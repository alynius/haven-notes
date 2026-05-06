# Haven iOS -- Product Audit Report

**Project:** Haven (iOS Note-Taking App)  
**Date:** 2026-04-22  
**Auditor:** Claude (Automated Deep Audit)  
**Platform:** iOS 17.0+ / SwiftUI / MVVM / Raw SQLite  
**Audit Depth:** Deep Dive (line-by-line, all 5 dimensions)  
**Codebase:** ~7,600 lines Swift across 75 production files, 0 external dependencies

---

## Executive Summary

Haven is a well-architected, privacy-focused iOS note-taking app with strong encryption primitives (PBKDF2 + AES-GCM via CryptoKit), zero third-party dependencies, and a clean MVVM codebase. The biggest risks are: (1) **two potential crash sites** from unguarded `sqlite3_column_text` nil pointers, (2) **Pro features (sync, encryption) have no subscription gate** -- any user can access them for free, and (3) **zero accessibility hints and zero Reduce Motion support** across the entire app, which would likely trigger an App Store rejection for accessibility non-compliance. On the positive side, the encryption implementation is textbook-correct, all SQL uses parameterized queries, and the design system (colors, fonts, spacing) is excellent.

**Key Finding:** The onboarding-to-paywall flow is broken -- `completeOnboarding()` removes the `OnboardingView` before the delayed paywall sheet can present, meaning the paywall never appears after first launch.  
**Top Recommendation:** Fix the 2 crash-path findings (sqlite3_column_text nil guard) and the subscription gate bypass -- these are all S-effort fixes that protect revenue and stability.

---

## Scorecard

| Dimension | Score | Status | Summary |
|-----------|-------|--------|---------|
| Security | 7/10 | Good | Encryption excellent, parameterized queries, no secrets. But: auth token not persisted, no subscription enforcement, FTS injection path. |
| Performance | 5/10 | Adequate | Good fundamentals (WAL, FTS, lazy init). But: double fetchAll, O(N*M) graph rebuild, highlighting without debounce, N+1 sidebar queries. |
| Code Quality | 6/10 | Adequate | Clean MVVM, protocols, no deps. But: 2 crash paths, data races in EncryptionService, sync creates duplicates, minimal unit tests. |
| UI/UX | 7/10 | Good | Excellent design system, loading/empty/error states. But: broken paywall flow, broken daily note deep link, no keyboard shortcuts, no undo delete. |
| Accessibility | 4/10 | Poor | Toolbar labels are good. But: zero hints, zero Reduce Motion, graph inaccessible, NoteRowView ungrouped, 10+ unlabeled buttons. |

**Overall Health: 6.0/10** (Weighted: Security 30% + Performance 20% + Code Quality 20% + UI 15% + Accessibility 15%)  
Status: **Adequate** -- functional and well-structured, but accessibility gaps and several correctness issues need attention before App Store submission.

### Overall Health Calculation

- Security: 7 x 0.30 = 2.10
- Performance: 5 x 0.20 = 1.00
- Code Quality: 6 x 0.20 = 1.20
- UI/UX: 7 x 0.15 = 1.05
- Accessibility: 4 x 0.15 = 0.60
- **Total: 5.95/10 (~6.0)**

---

## Findings by Severity

### Critical (4 found)

---

**Finding: `sqlite3_column_text` used without nil guard -- null pointer crash**  
**Dimension:** Code Quality  
**Location:** `Services/Sync/ChangeQueue.swift:27-30`, `Services/Sync/SyncManager.swift:101,133`, `Views/Settings/SettingsViewModel.swift:27`  
**Severity:** Critical  

**What:** `sqlite3_column_text()` returns a nullable pointer. In 6 places across 3 files, the result is passed directly to `String(cString:)` without a nil check. If a column is SQL NULL, the app crashes.

**Why it matters:** A corrupted database row, a failed migration, or a sync-pulled note with a NULL field will crash the app with no recovery path.

**Fix:** Replace all bare `String(cString: sqlite3_column_text(stmt, N))` with `DatabaseManager.columnTextNonNull(stmt, N)` -- the safe pattern already used everywhere else in the codebase.

**Effort:** S (< 1 hour)

---

**Finding: Protocol/implementation signature mismatch on `checkEntitlement()` silently swallows verification failures**  
**Dimension:** Code Quality  
**Location:** `Protocols/SubscriptionManagerProtocol.swift:15` vs `Services/Subscription/SubscriptionManager.swift:58`  
**Severity:** Critical  

**What:** The protocol declares `func checkEntitlement() async throws` but the implementation is `func checkEntitlement() async` (non-throwing). Inside the implementation, `try?` silently swallows StoreKit verification failures, falling through to `.free`.

**Why it matters:** A tampered receipt or intercepted transaction silently degrades to free tier instead of raising an error. Revenue protection is undermined.

**Fix:** Add `throws` to the implementation and propagate errors, or remove `throws` from the protocol and handle errors explicitly at call sites.

**Effort:** S

---

**Finding: No `.accessibilityHint()` used anywhere in the entire app**  
**Dimension:** Accessibility  
**Location:** All view files  
**Severity:** Critical  

**What:** Zero `.accessibilityHint()` modifiers exist across the codebase. Destructive actions (delete note), purchase actions (subscribe), and security actions (enable encryption, unlock) provide no VoiceOver hint about consequences.

**Why it matters:** VoiceOver users rely on hints for non-obvious actions. Apple's HIG explicitly recommends hints for actions where the result is not obvious from the label alone. App Review may flag this.

**Fix:** Add `.accessibilityHint()` to: delete actions, unlock button, encryption enable/disable, subscription purchase, tag remove, and task delete buttons. Minimum 10-15 additions.

**Effort:** M (half day)

---

**Finding: No Reduce Motion support -- all animations play unconditionally**  
**Dimension:** Accessibility  
**Location:** 15+ animation sites across the app  
**Severity:** Critical  

**What:** The app has ~20 animation call sites (`withAnimation`, `.animation()`, `.symbolEffect(.pulse)`, skeleton shimmer, toolbar press scale) and zero checks for `UIAccessibility.isReduceMotionEnabled` or `@Environment(\.accessibilityReduceMotion)`. The forever-repeating animations (skeleton shimmer, empty state pulse, onboarding floating icon) are especially problematic.

**Why it matters:** Users with vestibular disorders or motion sensitivity enable Reduce Motion to avoid animations. Perpetual animations violate WCAG 2.3.3.

**Fix:** Add `@Environment(\.accessibilityReduceMotion) var reduceMotion` and conditionally disable animations. Priority targets: skeleton shimmer, `.symbolEffect(.pulse)`, floating onboarding icons.

**Effort:** M

---

### High (14 found)

---

**Finding: Pro features (sync, encryption) have no subscription gate**  
**Dimension:** Security  
**Location:** `Views/Settings/SyncSettingsView.swift`, `Views/Settings/EncryptionSettingsView.swift`  
**Severity:** High  

**What:** CLAUDE.md states sync and encryption are Pro-only, but neither view checks subscription status. Any user can enable sync and encryption without paying.

**Why it matters:** Direct revenue bypass. All premium features accessible for free.

**Fix:** Inject `SubscriptionManager` and gate enable actions behind `entitlement == .pro`.

**Effort:** S

---

**Finding: Sync auth token stored in memory only -- lost on restart**  
**Dimension:** Security  
**Location:** `Services/Sync/SyncHTTPClient.swift:22`, `Services/Sync/SyncManager.swift:46-51`  
**Severity:** High  

**What:** The sync auth token is held as `private var authToken: String?`. Server URL is persisted to the database, but the token is not persisted anywhere. After app restart, the URL is known but the token is nil -- sync silently fails.

**Why it matters:** Sync breaks after every app restart. If someone "fixes" this by storing in UserDefaults, the token will be in plaintext on disk.

**Fix:** Store the auth token in Keychain with `kSecAttrAccessibleAfterFirstUnlock`. Load on launch when sync is enabled.

**Effort:** S

---

**Finding: Double `fetchAll()` in NoteListViewModel.loadNotes()**  
**Dimension:** Performance  
**Location:** `Views/NoteList/NoteListViewModel.swift:38`  
**Severity:** High  

**What:** After loading notes for display, `loadNotes()` calls `noteRepo.fetchAll()` a second time solely to get a count for the widget. Two full table scans per list load.

**Why it matters:** Every note list appearance triggers double the database work. Loads full `body_html` and `body_plaintext` for every note just to count them.

**Fix:** Replace with `SELECT COUNT(*) FROM notes WHERE is_deleted = 0`.

**Effort:** S

---

**Finding: Graph view rebuilds ALL links from scratch on every open**  
**Dimension:** Performance  
**Location:** `Views/Graph/GraphViewModel.swift:39-42`  
**Severity:** High  

**What:** `GraphViewModel.load()` calls `rebuildLinks()` for every single note before building the graph -- O(N * M) database operations. Links are already maintained on each note save.

**Why it matters:** For 200 notes with 2 links each: ~800 individual database queries every time the graph opens.

**Fix:** Remove the full rebuild loop. Links are already maintained incrementally during autosave.

**Effort:** S

---

**Finding: Markdown highlighting on every keystroke without debounce**  
**Dimension:** Performance  
**Location:** `Services/Editor/RichTextCoordinator.swift:110-111`  
**Severity:** High  

**What:** In `textViewDidChange`, `applyHighlighting()` runs 8 regex passes over the entire document text on every character typed. The existing `highlightDebounce` property and `highlightWorkItem` are declared but never used.

**Why it matters:** For notes with 5,000+ characters, 8 regex passes + full `NSAttributedString` rebuild per keystroke causes input lag.

**Fix:** Use the existing `highlightWorkItem` with a `DispatchWorkItem` to debounce highlighting to 50-100ms.

**Effort:** M

---

**Finding: Force unwraps on `statement!` in DatabaseManager core methods**  
**Dimension:** Code Quality  
**Location:** `Services/Database/DatabaseManager.swift:64,87,90`  
**Severity:** High  

**What:** After `sqlite3_prepare_v2`, the code force-unwraps `statement!`. While the guard checks SQLITE_OK, the statement pointer can still be NULL in edge cases.

**Why it matters:** Crash in the database layer brings down the entire app.

**Fix:** Use `guard let statement = statement else { return/throw }` after prepare.

**Effort:** S

---

**Finding: Force unwrap of `coordinator.textView!` in NoteEditorView**  
**Dimension:** Code Quality  
**Location:** `Views/NoteEditor/NoteEditorView.swift:154`  
**Severity:** High  

**What:** `coordinator.textView!` force-unwraps a `weak var textView: UITextView?`. If the text view has been deallocated during rapid navigation, this crashes.

**Fix:** Guard-let the textView before use.

**Effort:** S

---

**Finding: `EncryptionService` is not thread-safe -- mutable state accessed from `Task.detached`**  
**Dimension:** Code Quality  
**Location:** `Services/Encryption/EncryptionService.swift:8`, `Views/Settings/EncryptionSettingsView.swift:134-136`  
**Severity:** High  

**What:** `EncryptionService` has a mutable `private var masterKey: SymmetricKey?` accessed from `Task.detached` (background) and MainActor simultaneously. No synchronization.

**Why it matters:** Data race on the encryption key. Undefined behavior under Swift strict concurrency.

**Fix:** Make `EncryptionService` an actor, or add `@MainActor` and move CPU-intensive work to a nonisolated method.

**Effort:** M

---

**Finding: `SearchService.noteFromRow` omits `folder_id` column**  
**Dimension:** Code Quality  
**Location:** `Services/Database/SearchService.swift:103-113`  
**Severity:** High  

**What:** Notes returned from search always have `folderID = nil` because the SQL query and row parser don't include `folder_id`. `NoteRepository.noteFromRow` includes it at index 8.

**Why it matters:** Folder badges won't display for search results. Any folder-based logic on search results breaks silently.

**Fix:** Add `n.folder_id` to the SearchService SQL and parse it in noteFromRow.

**Effort:** S

---

**Finding: Sync pull creates duplicate notes instead of upserting**  
**Dimension:** Code Quality  
**Location:** `Services/Sync/SyncManager.swift:154`  
**Severity:** High  

**What:** When a remote note doesn't exist locally, `noteRepo.create()` generates a new `id`, discarding the remote note's original ID. Next sync sees it as new again, creating infinite duplicates.

**Fix:** Use `noteRepo.upsert(decryptedNote)` which preserves the original ID via INSERT OR REPLACE.

**Effort:** S

---

**Finding: WikiLinkAutocompleteView not anchored to cursor position**  
**Dimension:** UI/UX  
**Location:** `Views/NoteEditor/NoteEditorView.swift:147-160`  
**Severity:** High  

**What:** The autocomplete overlay appears at the bottom of the ZStack regardless of cursor position. If typing near the top of a long note, suggestions appear far away, possibly behind the keyboard.

**Why it matters:** Wiki links are a core differentiating feature. If autocomplete is unusable, the feature is effectively broken.

**Fix:** Calculate cursor rect from `UITextView.caretRect(for:)` and position the overlay relative to it.

**Effort:** L

---

**Finding: Onboarding paywall never appears -- race condition**  
**Dimension:** UI/UX  
**Location:** `Views/Onboarding/OnboardingView.swift:132-136`  
**Severity:** High  

**What:** "Start Writing" calls `completeOnboarding()` (which removes OnboardingView from hierarchy), then `asyncAfter(0.5)` tries to present a `.sheet` on the now-removed view. The paywall is dead code.

**Why it matters:** The primary monetization funnel after onboarding is broken. No user ever sees the paywall after first launch.

**Fix:** Move paywall presentation to `HavenNavigationStack`. After onboarding completes, check a flag and present it from the main navigation.

**Effort:** M

---

**Finding: Knowledge Graph inaccessible to VoiceOver**  
**Dimension:** Accessibility  
**Location:** `Views/Graph/GraphView.swift:105-184`  
**Severity:** High  

**What:** The Canvas-based graph is invisible to VoiceOver. Edges have no accessibility representation. Node positions use scale/offset transforms that VoiceOver cannot navigate meaningfully.

**Fix:** Add an accessible list alternative shown when VoiceOver is active. Each node lists connected notes. Add `.accessibilityRotor("Connections")`.

**Effort:** L

---

**Finding: NoteRowView fragments into 3-5 separate VoiceOver elements**  
**Dimension:** Accessibility  
**Location:** `Views/NoteList/NoteRowView.swift:8-52`  
**Severity:** High  

**What:** Each row's title, body preview, folder badge, pin icon, and timestamp are separate VoiceOver elements. No `.accessibilityElement(children: .combine)`. The pin icon has no label. With 50 notes, VoiceOver users swipe through 150-250 elements.

**Fix:** Add `.accessibilityElement(children: .combine)` or build a custom composite `.accessibilityLabel`. Add `.accessibilityLabel("Pinned")` to the pin icon.

**Effort:** S

---

### Medium (20 found)

---

**Finding: FTS query injection in NoteRepository.search**  
**Dimension:** Security  
**Location:** `Services/Database/NoteRepository.swift:182-187`  
**Severity:** Medium  

**What:** `NoteRepository.search()` appends `*` to user tokens without escaping FTS5 special characters. `SearchService.search()` correctly calls `escapeFTSToken()`, but `NoteRepository` does not. A double-quote in the search bar crashes the search.

**Fix:** Use `SearchService.escapeFTSToken()` in `NoteRepository.search()`, or consolidate search through `SearchService`.

**Effort:** S

---

**Finding: Keychain uses `kSecAttrAccessibleAfterFirstUnlock` -- not strongest protection**  
**Dimension:** Security  
**Location:** `Services/Encryption/EncryptionService.swift:93`  
**Severity:** Medium  

**What:** Encryption keys are accessible whenever the device has been unlocked once since boot, even while locked. For an E2E encryption app with biometric lock, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` would be more appropriate.

**Fix:** If background sync is not required, upgrade to `WhenUnlockedThisDeviceOnly`. If needed, document the tradeoff.

**Effort:** S

---

**Finding: No NSFileProtection on the SQLite database**  
**Dimension:** Security  
**Location:** `Services/Database/DatabaseManager.swift:15-22`  
**Severity:** Medium  

**What:** The SQLite database containing all note content has no explicit file protection. Default is `CompleteUntilFirstUserAuthentication`. Biometric lock is a UI gate only -- data is accessible on disk when device is locked.

**Fix:** Set `NSFileProtectionComplete` on the database file after opening.

**Effort:** S

---

**Finding: Sidebar N+1 query pattern for folder/tag counts**  
**Dimension:** Performance  
**Location:** `Views/Sidebar/SidebarViewModel.swift:28-48`  
**Severity:** Medium  

**What:** `loadAll()` makes 1 + F + T individual queries (loading full note objects) to count notes per folder and tag. With 10 folders and 15 tags: 26 queries.

**Fix:** Add `SELECT folder_id, COUNT(*) FROM notes GROUP BY folder_id` aggregate queries. Reduce to 3 queries.

**Effort:** M

---

**Finding: `fetchAll()` loads full note bodies into memory for list display**  
**Dimension:** Performance  
**Location:** `Services/Database/NoteRepository.swift:59-73`  
**Severity:** Medium  

**What:** Note list loads `body_html` and `body_plaintext` for every note. The list view only shows title, 2-line preview, and timestamp. 500 notes x 5KB body = ~5MB wasted.

**Fix:** Create `fetchAllSummaries()` selecting only `id, title, SUBSTR(body_plaintext, 1, 200), is_pinned, is_deleted, created_at, updated_at, folder_id`.

**Effort:** M

---

**Finding: `performSync()` is a no-op -- false sense of thread safety**  
**Dimension:** Performance / Code Quality  
**Location:** `Services/Database/DatabaseManager.swift:97-99`  
**Severity:** Medium  

**What:** `performSync` just executes its closure inline. The declared `queue` property is never used. Relies on `SQLITE_OPEN_FULLMUTEX` for actual safety.

**Fix:** Either remove `performSync` to avoid confusion, or implement properly with the declared queue.

**Effort:** S

---

**Finding: Sync timer lacks tolerance -- prevents CPU coalescing**  
**Dimension:** Performance  
**Location:** `Services/Sync/SyncManager.swift:189`  
**Severity:** Medium  

**What:** `Timer.scheduledTimer(withTimeInterval: 300)` without `.tolerance` prevents the system from coalescing this timer with other wake-ups.

**Fix:** Add `syncTimer?.tolerance = 60` (Apple recommends 20% of interval).

**Effort:** S

---

**Finding: `NoteRepository.update()` uses `HTMLSanitizer.stripHTML` but `upsert()` uses `MarkdownStripper.stripMarkdown`**  
**Dimension:** Code Quality  
**Location:** `Services/Database/NoteRepository.swift:78` vs `:103`  
**Severity:** Medium  

**What:** The `update()` path (used by sync pull) strips HTML, but the `upsert()` path strips markdown. Since the editor now stores markdown, `update()` produces incorrect plaintext for FTS indexing.

**Fix:** Change `update()` to use `MarkdownStripper.stripMarkdown()`.

**Effort:** S

---

**Finding: Duplicate `noteFromRow` and `recordSyncChange` across repositories**  
**Dimension:** Code Quality  
**Location:** `NoteRepository.swift:360-372`, `SearchService.swift:103-113`, `TaskRepository.swift:137-144`  
**Severity:** Medium  

**What:** `noteFromRow()` duplicated between NoteRepository and SearchService (already diverged -- folder_id bug). `recordSyncChange()` copy-pasted between NoteRepository and TaskRepository.

**Fix:** Extract into shared helpers.

**Effort:** M

---

**Finding: Three separate `BiometricService` instances bypass DI**  
**Dimension:** Code Quality  
**Location:** `App/HavenApp.swift:14`, `App/DependencyContainer.swift:59`, `Views/Settings/SettingsView.swift:8`  
**Severity:** Medium  

**What:** Three independent instances of `BiometricService`. Works by accident via UserDefaults but violates the DI pattern.

**Fix:** Use `DependencyContainer.biometricService` everywhere.

**Effort:** M

---

**Finding: `fatalError` on database initialization failure**  
**Dimension:** UI/UX  
**Location:** `App/HavenApp.swift:62`  
**Severity:** Medium  

**What:** When the database fails to initialize, the alert's only action calls `fatalError()`, crashing the app. No recovery path.

**Fix:** Offer "Try Again" and "Reset Database" options instead of crashing.

**Effort:** S

---

**Finding: Daily note deep link handler missing**  
**Dimension:** UI/UX  
**Location:** `Views/Shared/HavenNavigationStack.swift`  
**Severity:** Medium  

**What:** `haven://daily-note` widget deep link sets `appState.pendingAction = .openDailyNote`, but no view ever reads `pendingAction`. Widget taps do nothing.

**Fix:** Add `.onChange(of: appState.pendingAction)` handler that creates/navigates to daily note.

**Effort:** S

---

**Finding: Subscription page has no retry on product fetch failure**  
**Dimension:** UI/UX  
**Location:** `Views/Settings/SubscriptionView.swift:53-109`  
**Severity:** Medium  

**What:** If StoreKit product fetch fails, the user sees a red error at the bottom with no retry button. The products section is empty.

**Fix:** Add a "Try Again" button next to the error message.

**Effort:** S

---

**Finding: No "undo delete" mechanism despite soft-delete support**  
**Dimension:** UI/UX  
**Location:** `Views/NoteList/NoteListView.swift:164-173`  
**Severity:** Medium  

**What:** Notes are soft-deleted (`isDeleted` flag) but there is no UI to access deleted notes. No "Recently Deleted" section, no undo toast.

**Fix:** Add a "Recently Deleted" section in the sidebar, or a 5-second undo toast after deletion.

**Effort:** M

---

**Finding: RichTextEditor doesn't update highlighting on dark/light mode switch**  
**Dimension:** UI/UX  
**Location:** `Services/Editor/RichTextCoordinator.swift:83-87`  
**Severity:** Medium  

**What:** Theme is created once on init. Switching dark/light mode while viewing (not editing) a note leaves stale markdown colors until the user types.

**Fix:** Override `traitCollectionDidChange` to trigger re-highlighting.

**Effort:** S

---

**Finding: Subscription auto-renewal disclosure placed below purchase buttons**  
**Dimension:** UI/UX  
**Location:** `Views/Settings/SubscriptionView.swift:113-118`  
**Severity:** Medium  

**What:** Apple requires subscription terms visible before the purchase button. The disclosure is below the buttons.

**Fix:** Move the disclosure above the product cards or make the per-card labels more explicit.

**Effort:** S

---

**Finding: No keyboard shortcuts for editor or navigation (iPad)**  
**Dimension:** UI/UX + Accessibility  
**Location:** Entire codebase  
**Severity:** Medium  

**What:** Zero `.keyboardShortcut()` modifiers. No Cmd+B, Cmd+I, Cmd+N, Cmd+F support on iPad with keyboard.

**Why it matters:** Note-taking on iPad with keyboard is a primary use case. Competitors all support standard shortcuts.

**Fix:** Add `UIKeyCommand` for Cmd+B/I/K/H in the editor, and `.keyboardShortcut()` for Cmd+N, Cmd+F in navigation.

**Effort:** M

---

**Finding: Hardcoded font sizes in 8 locations don't scale with Dynamic Type**  
**Dimension:** Accessibility  
**Location:** `OnboardingPageView.swift:47,56`, `HavenApp.swift:105`, `GraphView.swift:43,144`, `EmptyStateView.swift:9`, `SearchView.swift:15,32`  
**Severity:** Medium  

**What:** `.font(.system(size: N))` without `.relativeTo()` does not scale with Dynamic Type settings.

**Fix:** Mark decorative icons as `.accessibilityHidden(true)`. For graph node labels (size 10), provide via the accessible list alternative.

**Effort:** S

---

**Finding: Toast auto-dismisses without VoiceOver announcement**  
**Dimension:** Accessibility  
**Location:** `Views/Shared/ToastManager.swift:13-24`  
**Severity:** Medium  

**What:** Toasts appear/disappear without `UIAccessibility.post(notification: .announcement)`. VoiceOver users never know a toast appeared.

**Fix:** Post announcement in `ToastManager.show()`.

**Effort:** S

---

**Finding: 10+ buttons across tags, tasks, backlinks, and dictation lack accessibility labels**  
**Dimension:** Accessibility  
**Location:** `TagPickerView.swift:32-48,65-72,81-103`, `TaskListView.swift:42-49`, `NoteEditorView.swift:79-91,104-126`  
**Severity:** Medium  

**What:** Tag remove buttons, tag add button, tag suggestions, task delete button, backlink buttons, and dictation banner elements have no `.accessibilityLabel()`. VoiceOver reads raw icon names.

**Fix:** Add descriptive labels: "Remove tag [name]", "Add tag", "Delete task: [text]", "Linked from [title]", "Dictation active".

**Effort:** S

---

### Low (17 found)

| # | Finding | Dimension | Location | Effort |
|---|---------|-----------|----------|--------|
| 1 | Biometric lock bypass via `--uitesting` flag not guarded by `#if DEBUG` | Security | `HavenApp.swift:10-11` | S |
| 2 | Entitlements files empty -- App Groups not configured for widget | Security | `Haven.entitlements` | S |
| 3 | No HTTPS-only validation on sync server URL input | Security | `SyncSettingsViewModel.swift:31` | S |
| 4 | Regex objects re-created on every highlighting pass | Performance | `MarkdownHighlighter.swift` | S |
| 5 | `SpeechRecognizer` instantiated per editor, not shared | Performance | `NoteEditorViewModel.swift:17` | S |
| 6 | Sync log table grows unbounded -- `purgeSynced()` never called | Performance | `ChangeQueue.swift` | S |
| 7 | `onChange(of:)` uses deprecated iOS 16 signature (6 locations) | Code Quality | Multiple files | S |
| 8 | O(n^2) graph simulation step -- fine for now, scales poorly | Code Quality | `GraphViewModel.swift:110-177` | L |
| 9 | Force unwrap in `EncryptionService.generateSalt()` | Code Quality | `EncryptionService.swift:44` | S |
| 10 | Force unwrap URLs in SubscriptionView | Code Quality | `SubscriptionView.swift:132,134` | S |
| 11 | Hardcoded spacing values in NoteEditorView/EditorToolbarView bypass design tokens | UI/UX | `NoteEditorView.swift`, `EditorToolbarView.swift` | S |
| 12 | Sidebar "Today's Note" doesn't participate in selection binding | UI/UX | `SidebarView.swift:17-34` | S |
| 13 | ToastView not dismissible and may block interaction area | UI/UX | `ToastView.swift` | S |
| 14 | Graph node labels use hardcoded font size 10 | UI/UX | `GraphView.swift:145` | S |
| 15 | Decorative icons not hidden from VoiceOver (6 locations) | Accessibility | Multiple files | S |
| 16 | Section headers not marked with `.isHeader` trait | Accessibility | `TagPickerView.swift:26`, `TaskListView.swift:16` | S |
| 17 | Skeleton loading views have no accessibility representation | Accessibility | `SkeletonView.swift` | S |

### Info (5 found)

| # | Finding | Dimension | Location |
|---|---------|-----------|----------|
| 1 | No certificate pinning for sync server (acceptable for self-hosted model) | Security | `SyncHTTPClient.swift` |
| 2 | No `Sendable` conformance on any model type (Swift 6 readiness) | Code Quality | All models |
| 3 | Unit test coverage is minimal -- only 4 test files, zero for DB/sync/encryption | Code Quality | `HavenTests/` |
| 4 | DesignTokens comment says "8pt Grid" but values use 4pt base | UI/UX | `DesignTokens.swift:3` |
| 5 | Duplicate `Folder` model in test target shadows main target | Code Quality | `HavenTests/Models/Folder.swift` |

---

## What's Working Well

### Security
1. **Encryption is textbook-correct**: PBKDF2 with 600K iterations, SHA-256 PRF, 32-byte random salt via `SecRandomCopyBytes`, AES-GCM via CryptoKit with auto-generated nonces. No nonce reuse possible.
2. **All database queries use parameterized statements**: Every query across all 6 repositories uses `?` placeholders. Zero string interpolation of user input into SQL.
3. **No hardcoded secrets**: Zero API keys, passwords, or tokens anywhere in the source.
4. **No logging of sensitive data**: Zero `print()`, `NSLog()`, or `os_log()` in production code.
5. **Encryption applied before sync**: Server never sees plaintext when encryption is enabled.
6. **ATS not weakened**: No `NSAllowsArbitraryLoads`. Default HTTPS enforcement.
7. **Deep link handling is safe**: Only accepts `new-note` and `daily-note` hosts with `default: break`.
8. **Speech recognition prefers on-device**: `requiresOnDeviceRecognition = true` when available.

### Performance
1. **Lazy initialization in DependencyContainer**: All services use `lazy var`.
2. **WAL mode and proper SQLite config**: WAL journal, foreign keys, `SQLITE_OPEN_FULLMUTEX`.
3. **FTS5 for search**: Properly implemented with prefix matching, rank ordering, snippet support.
4. **Good indexes**: All frequently-queried columns indexed.
5. **Autosave debounce**: 1-second debounce properly cancels previous tasks.
6. **Search debounce**: 200ms with cancellation.
7. **SwiftUI List virtualization**: Uses built-in `List` (not `ScrollView + ForEach`).

### Code Quality
1. **Clean MVVM separation**: ViewModels contain no UI code, views contain no business logic.
2. **Protocol-based DI**: All services have protocols, DependencyContainer is the single composition root.
3. **Proper `@MainActor` usage**: All ViewModels correctly annotated.
4. **Zero external dependencies**: Built entirely on Apple frameworks.
5. **Good model design**: All models are value types, Codable, Hashable.
6. **Proper `.task` over `.onAppear`**: Data loading auto-cancels.

### UI/UX
1. **Excellent adaptive color system**: Every custom color has explicit light/dark variants.
2. **Full Dynamic Type support in design tokens**: All `Font+Haven` styles use system text styles.
3. **Comprehensive loading states**: Skeleton views with shimmer, progress indicators, loading overlays.
4. **Thoughtful empty states**: Pulsing icons, helpful copy, CTA buttons.
5. **Consistent error pattern**: `errorMessage` + `.alert` on every ViewModel.
6. **Editor toolbar**: 44pt touch targets, haptic feedback, active state indicators.
7. **Onboarding narrative**: 6 well-crafted pages with staggered animations.

### Accessibility
1. **Editor toolbar labels**: Every formatting button has an `.accessibilityLabel()` and `.accessibilityAddTraits(.isSelected)` for active state.
2. **NoteListView toolbar labels**: All 5 toolbar buttons properly labeled.
3. **LoadingOverlayView**: Properly uses `.accessibilityElement(children: .combine)` and `.updatesFrequently`.
4. **WikiLinkAutocompleteView**: Good container labeling with count announcement.
5. **TaskListView toggle buttons**: Contextual labels ("Mark complete"/"Mark incomplete").

---

## Recommended Next Steps

### Phase 1: Critical Fixes (Day 1-2)
- [ ] Guard all bare `sqlite3_column_text` calls with `columnTextNonNull()` -- **S, 6 locations**
- [ ] Fix `checkEntitlement()` protocol/implementation mismatch -- **S**
- [ ] Add subscription gate to SyncSettingsView and EncryptionSettingsView -- **S**
- [ ] Fix sync pull to use `upsert()` instead of `create()` -- **S**
- [ ] Fix `SearchService.noteFromRow` to include `folder_id` -- **S**
- **Impact:** Eliminate crash paths, prevent duplicate notes, protect revenue

### Phase 2: Revenue & Onboarding (Day 3-4)
- [ ] Fix onboarding paywall race condition -- move paywall to HavenNavigationStack -- **M**
- [ ] Fix daily note deep link handler -- add `pendingAction` observer -- **S**
- [ ] Add retry button on subscription product fetch failure -- **S**
- [ ] Move subscription disclosure above purchase buttons -- **S**
- [ ] Store sync auth token in Keychain -- **S**
- **Impact:** Restore monetization funnel, fix widget, improve conversion

### Phase 3: Performance (Day 5-7)
- [ ] Replace double `fetchAll()` with COUNT query -- **S**
- [ ] Remove full link rebuild in GraphViewModel -- **S**
- [ ] Wire up existing markdown highlight debounce -- **M**
- [ ] Add aggregate COUNT queries for sidebar -- **M**
- [ ] Create lightweight `fetchAllSummaries()` for note list -- **M**
- [ ] Add timer tolerance to sync timer -- **S**
- [ ] Pre-compile regex objects as static lets -- **S**
- **Impact:** Dramatically faster note list, graph, and editor

### Phase 4: Accessibility (Day 8-12)
- [ ] Add Reduce Motion checks to all animation sites -- **M**
- [ ] Add `.accessibilityHint()` to 15+ actions -- **M**
- [ ] Add `.accessibilityElement(children: .combine)` to NoteRowView -- **S**
- [ ] Add missing labels to tags, tasks, backlinks, dictation -- **S**
- [ ] Build accessible list alternative for knowledge graph -- **L**
- [ ] Add keyboard shortcuts (Cmd+B/I/N/F) -- **M**
- [ ] Post VoiceOver announcements for toasts -- **S**
- **Impact:** Bring accessibility from 4/10 to 7+/10, App Store compliance

### Phase 5: Code Quality & Polish (Day 13-15)
- [ ] Make EncryptionService an actor (thread safety) -- **M**
- [ ] Guard force unwraps in DatabaseManager, EncryptionService -- **S**
- [ ] Consolidate duplicate `noteFromRow`/`recordSyncChange` -- **M**
- [ ] Unify markdown stripping in `NoteRepository.update()` -- **S**
- [ ] Migrate deprecated `onChange(of:)` calls -- **S**
- [ ] Fix dark mode trait change re-highlighting -- **S**
- [ ] Consolidate BiometricService instances -- **M**
- [ ] Add `#if DEBUG` guard on `--uitesting` flag -- **S**
- **Impact:** Eliminate data races, reduce crash surface, improve maintainability

---

**Report prepared by:** Claude (Automated Deep Audit)  
**Follow-up audit recommended in:** 4-6 weeks after Phase 1-4 completion  
**Methodology:** Automated scan + manual line-by-line review of all 75 production Swift files across 5 dimensions
