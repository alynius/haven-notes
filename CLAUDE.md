# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Generate Xcode project from project.yml (XcodeGen)
xcodegen generate

# Build
xcodebuild -project Haven.xcodeproj -scheme Haven -configuration Debug -destination "generic/platform=iOS" build

# Run tests
xcodebuild test -project Haven.xcodeproj -scheme Haven -destination "platform=iOS Simulator,name=iPhone 16"

# Archive for App Store
xcodebuild archive -project Haven.xcodeproj -scheme Haven -configuration Release -archivePath /tmp/Haven.xcarchive -destination "generic/platform=iOS" -allowProvisioningUpdates CODE_SIGN_STYLE=Automatic

# Upload to App Store Connect
xcodebuild -exportArchive -archivePath /tmp/Haven.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath /tmp/HavenExport -allowProvisioningUpdates
```

## Architecture

**Pattern**: MVVM with a service layer. ViewModels handle UI logic, Services handle business logic, Repositories handle data access.

**Dependency Injection**: `DependencyContainer` (singleton) creates and owns all services/repositories. Views access it via `@EnvironmentObject`.

**Navigation**: `NavigationStack` with a `Route` enum and `NavigationPath`. iPad uses sidebar + detail split view. Deep links via `haven://` URL scheme handled by `DeepLinkHandler`.

**State**: `AppState` manages global state (selected note, navigation, theme). No external state management libraries.

### Data Layer

SQLite 3 directly (not CoreData/SwiftData). `DatabaseManager` singleton manages the connection with WAL mode and foreign keys.

Key tables: `notes` (HTML + plaintext), `tasks`, `links` (wiki link graph), `folders`, `tags`, `note_tags`, `sync_log` (change queue), `app_settings`. FTS via `notes_fts` table.

Repository pattern: `NoteRepository`, `TaskRepository`, `FolderRepository`, `TagRepository`, `LinkRepository` — all use `DatabaseManager` for queries.

### Sync Architecture

`SyncManager` implements bidirectional sync with a remote server. Uses a **change queue** pattern: local edits write to `sync_log`, which is drained during sync. **Last-write-wins** conflict resolution. Notes use **soft deletes** (marked deleted, not removed).

Sync and encryption are **Pro-only** features gated by `SubscriptionManager` (StoreKit 2).

### Encryption

`EncryptionService` provides optional E2E encryption using PBKDF2 key derivation + AES-GCM. Keys stored in Keychain. Encryption is per-note and applied before sync.

### Key Services

- `SyncManager` — server sync with change queue
- `EncryptionService` — AES-GCM encryption with Keychain key storage
- `SubscriptionManager` — StoreKit 2, products: `com.haven.pro.monthly`, `com.haven.pro.yearly`
- `BiometricService` — Face ID / Touch ID app lock
- `NotionImporter` — imports Markdown from Notion exports
- `WikiLinkParser` — `[[link]]` parsing and autocomplete
- `SearchService` — full-text search via FTS
- `DailyNoteService` — daily note creation
- `SpeechRecognizer` — voice dictation

## Project Structure

```
Haven/          — Main app target (iOS 17.0+, Swift 5.9)
HavenWidget/    — WidgetKit extension (quick note + daily note widgets)
HavenTests/     — XCTest unit tests
project.yml     — XcodeGen project definition
```

App Groups (`group.com.havennotes.app`) shared between main app and widget. Widget deep links: `haven://new-note`, `haven://daily-note`.

## Important Patterns

- **Autosave**: 1-second debounce on note edits
- **Dual storage**: Notes store both HTML (rendering) and plaintext (search/FTS)
- **No external dependencies**: Everything uses Apple frameworks (SwiftUI, StoreKit, CryptoKit, SQLite3, WidgetKit, LocalAuthentication)
- **StoreKit config**: `Configuration.storekit` file for sandbox testing
- **Bundle ID**: `com.havennotes.app`
- **Team ID**: `T592C9M4H4`
