# Haven — Cross-Platform Audit Report (iOS + macOS + Parity)

**Date:** 2026-04-30
**Branch:** feat/macos-app
**Targets audited:** Haven (iOS), HavenMac (macOS 14+)
**Codebase:** ~85 Swift files / ~8,250 LOC, raw SQLite, 0 external deps
**Prior baseline:** 2026-04-22 (iOS only, 6.0/10 → claimed 7.7 after 5 fix phases)

---

## Executive Summary

Haven on iOS has improved meaningfully since the last audit — Pro features are now gated, the post-onboarding paywall finally shows, Reduce Motion is widely respected, and editor highlighting is debounced. **iOS health: 6.9/10**, no regressions, one Critical (a force unwrap in the editor) and a handful of Mediums.

The **macOS target is functionally complete but not Mac App Store ready**. Two non-negotiable blockers — an **empty entitlements file** (App Sandbox disabled) and **no Hardened Runtime** — will fail notarization. A Carbon-Event hotkey leak, a Quick Note retention bug, NSTextView re-rendering the entire text storage on every keystroke, and zero accessibility labels in Mac-specific code round out the critical work. **macOS health: 4.4/10.**

The two apps **share a strong foundation** (services, repositories, models, sync, encryption, FTS) but **diverge in the presentation layer**: the editor toolbar, voice dictation, and wiki-link autocomplete simply don't exist on Mac, and the lock screen + settings UI are visibly less polished. **Parity score: 6.5/10.**

**Top recommendation:** Before any Mac App Store submission, fix the three macOS Critical blockers (entitlements, hardened runtime, hotkey leak). Before the next iOS release, fix the editor force-unwrap. Then close the parity gap — speech recognition, editor toolbar, and wiki autocomplete on Mac are the highest-ROI three.

---

## Score Cards

### iOS (Haven)

| Dimension | Score | Δ vs 2026-04-22 | Summary |
|-----------|-------|-----|---------|
| Security | 7.5/10 | +0.5 | Pro gates enforced; encryption excellent; keychain accessibility sub-optimal. |
| Performance | 6.5/10 | +1.5 | Highlight debounce wired; sync timer tolerance set; one duplicate count query. |
| Code Quality | 6.5/10 | +0.5 | Markdown stripping unified; FTS injection fixed; one force unwrap on textView remains. |
| UI/UX | 8.0/10 | +1.0 | Onboarding paywall + daily-note deep link fixed; keyboard shortcuts still missing. |
| Accessibility | 5.5/10 | +1.5 | Reduce Motion broadly added; toast announcements; hints still sparse on destructive actions. |
| **Overall** | **6.9/10** | **+0.9** | Good. No regressions. |

### macOS (HavenMac)

| Dimension | Score | Summary |
|-----------|-------|---------|
| Security | 3.0/10 | Empty entitlements, no hardened runtime, hotkey permission undeclared, lock bypass via Quick Note. |
| Performance | 6.0/10 | Full text-storage regeneration per keystroke; Quick Note panel retained on close. |
| Code Quality | 5.0/10 | Hotkey handler leak, no `unregister()` on quit, notification-based commands. |
| UI/UX | 6.0/10 | Polished Quick Note; missing standard Edit/View/Window/Help menus; no window restoration. |
| Accessibility | 2.0/10 | Zero a11y labels in Mac-only code; "Touch ID" mislabeled; menu commands undocumented for VoiceOver. |
| **Overall** | **4.4/10** | Not App Store ready. |

### Parity (iOS ↔ macOS)

| Score | Reasoning |
|-------|-----------|
| **6.5/10** | Strong shared foundation; presentation layer diverges. Voice, toolbar, wiki autocomplete absent on Mac. |

---

## 🔴 Critical Findings (4)

### 🔴 [iOS] Force unwrap on `coordinator.textView!`
**Dimension:** Code Quality
**Location:** `Views/NoteEditor/NoteEditorView.swift:183`
**What:** iOS branch force-unwraps a weak optional after wiki-link autocomplete; macOS branch (lines 187-189) already uses `guard let`.
**Why:** Race during rapid navigation crashes the editor — the most-used flow.
**Fix:** Mirror the macOS guard-let pattern.
**Effort:** S

### 🔴 [macOS] Empty `HavenMac.entitlements` — App Sandbox disabled
**Dimension:** Security
**Location:** `Haven/HavenMac.entitlements`
**What:** Empty `<dict/>`. App runs with unrestricted FS, network, IPC.
**Why:** **Mac App Store blocker** — sandbox is mandatory. Also removes the security boundary protecting user data.
**Fix:** Add `com.apple.security.app-sandbox = true`, plus minimum required entitlements (`com.apple.security.network.client` for sync, `com.apple.security.files.user-selected.read-write` for Notion import). Verify with `codesign -d --entitlements=- HavenMac.app`.
**Effort:** M

### 🔴 [macOS] Hardened Runtime not enabled
**Dimension:** Security
**Location:** `project.yml:104-112` (HavenMac settings)
**What:** No `ENABLE_HARDENED_RUNTIME` setting.
**Why:** Notarization blocker. Allows runtime patching, unsigned-code injection.
**Fix:** Add `ENABLE_HARDENED_RUNTIME: YES` to `HavenMac.settings.base`. Don't add `allow-unsigned-executable-memory` (no JIT needed for a notes app).
**Effort:** S

### 🔴 [macOS] Carbon-Event hotkey handler leak
**Dimension:** Code Quality / Security
**Location:** `Mac/GlobalHotkey.swift:21-24`
**What:** `InstallEventHandler` is called once but never paired with `RemoveEventHandler`. The closure retains `GlobalHotkeyManager.shared`. No `unregister()` call on app termination.
**Why:** Memory leak for app lifetime; a leaked event tap can keep intercepting Cmd+Shift+N system-wide until system restart, interfering with other apps.
**Fix:** Store the `EventHandlerRef`, add an `unregister()` that calls `RemoveEventHandler`, and invoke it from `applicationWillTerminate` or `scenePhase == .background`.
**Effort:** M

---

## 🟠 High Findings (10)

### 🟠 [iOS] Double-fetch on note list load
**Location:** `Views/NoteList/NoteListViewModel.swift:37-40`
**What:** After `fetchAll()`, a second `countAll()` fires for the widget App-Group count.
**Fix:** Use `notes.count` from the loaded array (already filtered for `is_deleted = 0`).
**Effort:** S

### 🟠 [macOS] NSTextView regenerates full attributed string per keystroke
**Location:** `Mac/MacTextViewCoordinator.swift:95-108`
**What:** `applyHighlighting` calls `setAttributedString(highlighted)` on every (debounced 50 ms) edit, replacing the entire text storage.
**Why:** Editing a 10K-word note will stutter; scroll-position jitter; allocation pressure.
**Fix:** Apply attributes incrementally via `textStorage.addAttributes(_:range:)` over only the changed range. Or bump debounce to 200 ms for large docs.
**Effort:** L

### 🟠 [macOS] Quick Note panel retains content view after close
**Location:** `Mac/QuickNotePanel.swift:20-31, 47`
**What:** `isReleasedWhenClosed = false`. NSHostingView is recreated on `show()` but the previous one isn't torn down.
**Fix:** Set `isReleasedWhenClosed = true` and recreate panel on each show, OR explicitly nil out `panel` in `hide()`.
**Effort:** M

### 🟠 [macOS] Quick Note callable while app is locked
**Location:** `App/HavenApp.swift:84-89` (hotkey registered in `onAppear`, before unlock)
**What:** Global hotkey is registered unconditionally. With biometric lock on, attacker with physical access can summon Quick Note and write notes that bypass the lock screen.
**Fix:** Move `GlobalHotkeyManager.shared.register` to fire only after `isLocked == false`. Gate the notification handler with the same check.
**Effort:** M

### 🟠 [macOS] Global hotkey requires Accessibility permission, not declared
**Location:** `Mac/GlobalHotkey.swift:21-25`, `MacInfo.plist`
**What:** Carbon Event handlers still need Accessibility on macOS 10.14+. No upfront UI explains the prompt; silent denial = silent hotkey failure.
**Fix:** Add user-facing explanation on first launch ("Cmd+Shift+N requires Accessibility — enable in System Settings"). Optionally migrate to `NSEvent.addLocalMonitorForEvents` where appropriate.
**Effort:** M

### 🟠 [macOS] Quick Note panel has zero accessibility labels
**Location:** `Mac/QuickNotePanel.swift:62-144`
**What:** No `.accessibilityLabel`, `.accessibilityHint`, or `.accessibilityElement` on title field, body field, or save/discard buttons.
**Fix:** Label title field as "Note title", body as "Note body" with hint "Cmd+Return to save, Esc to discard".
**Effort:** S

### 🟠 [macOS] BiometricService labels Mac as "Touch ID"
**Location:** `Mac/MacSettingsView.swift:44`, `Services/Security/BiometricService.swift:16-20`
**What:** Most Macs don't have Touch ID. macOS biometric availability depends on Apple Silicon laptops with Touch ID, or Apple Watch unlock.
**Fix:** Detect actual capability via `LAContext.canEvaluatePolicy` and label dynamically ("Apple Watch", "Touch ID", or hide the toggle if neither is available).
**Effort:** S

### 🟠 [Parity] Voice dictation missing on Mac
**Location:** `Services/Editor/SpeechRecognizer.swift:146-157` (macOS branch is a stub)
**What:** iOS uses `AVAudioEngine + SFSpeechRecognizer`; macOS branch returns no-ops.
**Fix:** `SFSpeechRecognizer` works on macOS 10.15+. Wire it into MacEditorView. Add `NSSpeechRecognitionUsageDescription` and `NSMicrophoneUsageDescription` to `MacInfo.plist`.
**Effort:** M

### 🟠 [Parity] Editor toolbar missing on Mac
**Location:** `Views/NoteEditor/EditorToolbarView.swift` (iOS-only)
**What:** iOS gets a 7-button toolbar (Bold, Italic, Heading, List, Checkbox, Link, Mic). macOS users must use menu shortcuts only.
**Fix:** Either show the same SwiftUI toolbar on Mac (it already uses cross-platform symbols), or build an `NSToolbar` that mirrors the same actions to MacTextViewCoordinator.
**Effort:** M

### 🟠 [iOS+macOS] `SpeechRecognizer.swift` macro-guard inconsistency
**Location:** `Services/Editor/SpeechRecognizer.swift:146-151`
**What:** Stub block is wrapped `#if os(macOS)` but the rest of the file is unconditionally compiled — fragile.
**Fix:** Wrap the whole file `#if os(iOS)` (until Mac implementation lands), or split into platform files.
**Effort:** S

---

## 🟡 Medium Findings (8)

### 🟡 [iOS] Keychain accessibility uses `AfterFirstUnlock`
**Location:** `Services/Encryption/EncryptionService.swift:98`
**Fix:** Switch to `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` unless background sync explicitly requires the looser policy.
**Effort:** S

### 🟡 [macOS] Standard menus incomplete (Edit, View, Window, Help)
**Location:** `Mac/MacMenuCommands.swift:29-97`
**What:** Format menu is great, but Edit (Undo/Redo/Cut/Copy/Paste), View (Zoom/Full Screen), Window (Minimize/Cycle), and Help are using SwiftUI defaults — Cmd+S/Cmd+Z behaviour is partially missing.
**Fix:** `CommandGroup(replacing: .undoRedo)`, ensure Cmd+S maps to explicit autosave flush, add Help → "Haven Help" linking to docs.
**Effort:** M

### 🟡 [macOS] No window state restoration
**Location:** `App/HavenApp.swift:32`
**Fix:** Use `@SceneStorage` for window frame, or implement `NSWindowRestoration`.
**Effort:** M

### 🟡 [macOS] Keyboard shortcut coverage thin
**Location:** `Mac/MacMenuCommands.swift`
**What:** Cmd+S, Cmd+T (rename note), Cmd+Opt+L (toggle sidebar), Cmd+Opt+± (heading level) are missing.
**Fix:** Add to `MacMenuCommands` and surface in Help.
**Effort:** S

### 🟡 [macOS] No drag-and-drop
**Location:** `Views/NoteList/NoteListView.swift`, `Mac/MacEditorView.swift`
**Fix:** `.onDrop(of: [.fileURL], delegate:)` on the editor for file imports; reorder via `.draggable`/`.dropDestination` on rows.
**Effort:** L

### 🟡 [Parity] Wiki link autocomplete missing on Mac
**Location:** `Views/NoteEditor/WikiLinkAutocompleteView.swift` (iOS only)
**Fix:** Reuse the SwiftUI view as an `NSPopover` anchored to the NSTextView caret rect.
**Effort:** M

### 🟡 [Parity] Settings parity gap
**Location:** `Mac/MacSettingsView.swift` (~50 LOC) vs `Views/Settings/SettingsView.swift` (~150 LOC)
**What:** About section, version, tagline, attribution missing on Mac.
**Fix:** Mirror the iOS About section into `MacSettingsView`'s General tab.
**Effort:** S

### 🟡 [macOS] Hotkey not unregistered on quit
**Location:** `Mac/GlobalHotkey.swift:28-33`
**Fix:** Implement `unregister()` and call from `applicationWillTerminate`.
**Effort:** S

---

## 🔵 Low / ⚪ Info (selected)

- **🔵 [macOS]** Title bar style inconsistent between main window and Quick Note (`Mac/QuickNotePanel.swift:43-44`). Decide on unified or transparent — apply to both.
- **🔵 [macOS]** `markdownHighlighter.updateTheme(for: effectiveAppearance)` runs every keystroke (`Mac/MacTextViewCoordinator.swift:92`). Cache previous appearance, only update on change.
- **🔵 [macOS]** Menu commands posted via `NotificationCenter` — no type safety. Switch to `@FocusedValue` for editor commands.
- **🔵 [Parity]** Lock screen on Mac is plain text+button vs animated iOS LockScreenView. Backport the design.
- **🔵 [Parity]** Onboarding uses `.tabViewStyle(.page)` on iOS only — Mac falls back to default tab layout.
- **⚪ [macOS]** `NSApp.keyWindow` deprecated in macOS 14 (`Views/Shared/HavenNavigationStack.swift:87`). Use `NSApplication.shared.mainWindow`.
- **⚪ [macOS]** `PrivacyInfo.xcprivacy` doesn't list the global-hotkey API category. Add when speech recognition lands on Mac.
- **⚪** 8 callers use the deprecated 2-arg `onChange(of:)` signature. Migrate to 3-arg form.
- **⚪ [false-positive review]** macOS auditor flagged the new "Continue with Haven Free" button as "missing on paid tier" — verified safe: the button is gated `isModal: true` which is only set at the post-onboarding sheet site (`HavenApp.swift:60-65`). Settings push uses NavigationStack back-button; Pro users never see the post-onboarding sheet. **No action needed.**

---

## Feature Parity Matrix

| Feature | iOS | macOS | Notes |
|---|---|---|---|
| Note CRUD | ✅ | ✅ | Shared services |
| Folders + tags | ✅ | ✅ | |
| Wiki links `[[…]]` | ✅ | ✅ | Both render |
| Wiki link **autocomplete** | ✅ | ❌ | iOS-only popup |
| Knowledge graph | ✅ | ✅ | |
| FTS search | ✅ | ✅ | |
| Daily note + deep link | ✅ | ✅ | |
| **Editor toolbar (Bold/Italic/etc.)** | ✅ | ❌ | Mac has menu commands only |
| **Voice dictation** | ✅ | ❌ | macOS branch is a stub |
| Markdown highlighting | ✅ | ✅ | |
| Biometric app lock | ✅ Face ID | ⚠️ mislabeled | "Touch ID" inaccurate on most Macs |
| Lock screen UI | ✅ animated | ⚠️ basic | |
| Subscription / paywall | ✅ | ✅ | Dismiss now works on both |
| Sync (Pro) | ✅ | ✅ | Shared SyncManager |
| Encryption (Pro) | ✅ | ✅ | Shared EncryptionService |
| Notion import | ✅ | ✅ | |
| Onboarding | ✅ paged | ⚠️ default | Tab style differs |
| Settings — full coverage | ✅ | ⚠️ trimmed | About missing on Mac |
| Toast notifications | ✅ | ✅ | |
| Context menus (Pin/Delete) | ✅ long-press | ✅ right-click | |
| **Quick Note** | ❌ (Widget) | ✅ Cmd+Shift+N | Different but equivalent |
| **Widget** | ✅ | ❌ | Acceptable platform asymmetry |
| **Menu bar commands** | n/a | ⚠️ partial | Edit/View/Window/Help incomplete |
| Drag & drop | ❌ | ❌ | Neither |
| Keyboard shortcuts | ❌ | ⚠️ partial | iOS has none; Mac has format only |
| Multiple windows | ❌ | ❌ | |
| Export / share | ❌ | ❌ | |

Legend: ✅ full · ⚠️ partial · ❌ missing

---

## What's Working Well

**Shared foundation** — every audit agreed on these:
1. **Encryption is textbook-correct.** PBKDF2 (600K iterations) + AES-GCM via CryptoKit, random nonces, salt + key in Keychain.
2. **Zero external dependencies.** Apple frameworks only — long-term maintenance win.
3. **All SQL is parameterized.** Repository pattern is consistent.
4. **Pro features are now genuinely gated.** Sync and encryption views check `subscriptionManager.entitlement`.
5. **Clean MVVM, no business logic in views.** Services are protocol-fronted; `DependencyContainer` is the DI root.
6. **WAL + FULLMUTEX SQLite.** Concurrent reads are safe.
7. **Onboarding paywall now actually presents.** Was broken in the prior audit.

**iOS-specific strengths:** Reduce Motion respected at 5+ animation sites, toast VoiceOver announcements, NoteRowView grouped for screen readers, FTS escape hardening, sync timer tolerance, debounced highlighting.

**macOS-specific strengths:** Clean Mac/ folder isolation, Quick Note UX is genuinely polished, Carbon hotkey works reliably (modulo the leak), Markdown highlighter respects effective appearance for dark mode.

---

## Prioritized Next Steps

### Phase 6 — Must-fix before any release
1. 🔴 Mirror guard-let onto iOS `coordinator.textView!` (`NoteEditorView.swift:183`) — **S**
2. 🔴 Enable App Sandbox in `HavenMac.entitlements` — **M**
3. 🔴 Enable Hardened Runtime in `project.yml` (HavenMac) — **S**
4. 🔴 Fix Carbon hotkey leak + `unregister()` on quit — **M**
5. 🟠 Gate Quick Note hotkey behind unlock state — **M**

### Phase 7 — Mac App Store readiness
6. 🟠 Quick Note a11y labels — **S**
7. 🟠 Update PrivacyInfo.xcprivacy + MacInfo.plist (mic, hotkey, speech) — **S**
8. 🟠 NSTextView incremental highlighting — **L**
9. 🟠 Quick Note panel teardown — **M**
10. 🟠 Biometric label correctness on Mac — **S**

### Phase 8 — Parity (the "match on everything" goal)
11. 🟠 Implement macOS speech recognition (`SFSpeechRecognizer`) — **M**
12. 🟠 Editor toolbar on Mac (port SwiftUI view or NSToolbar mirror) — **M**
13. 🟡 Wiki link autocomplete on Mac (NSPopover) — **M**
14. 🟡 About section in MacSettingsView — **S**
15. 🟡 Standard Edit/View/Window/Help menus + Cmd+S — **M**
16. 🟡 Window state restoration via `@SceneStorage` — **M**
17. 🔵 Lock screen polish + onboarding tab style on Mac — **S each**

### Phase 9 — Hygiene
18. 🟡 Keychain → `WhenUnlockedThisDeviceOnly` — **S**
19. 🟡 Drag and drop (file → editor, row reorder) — **L**
20. 🔵 Migrate deprecated `onChange(of:)` callers (8) — **S**
21. 🔵 Fix `NSApp.keyWindow` deprecation — **S**

---

## Mac App Store Verdict

**❌ Not ready.** Three blockers (entitlements, hardened runtime, hotkey leak) plus the locked-app Quick-Note bypass must land before submission. Estimated 2–3 days of focused work to clear blockers; another 5–7 days for reasonable Phase 7 polish before App Review.

Once those land and the Phase 8 parity items ship, both apps will plausibly score 8+/10 with parity at ~9/10.
