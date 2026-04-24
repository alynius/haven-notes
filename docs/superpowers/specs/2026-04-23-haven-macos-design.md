# Haven for Mac -- Design Spec

**Date:** 2026-04-23
**Status:** Approved
**Author:** Claude + Younes

---

## Overview

Haven for Mac is a native macOS companion to the existing iOS app. It shares the same codebase, same database format, same sync protocol, and the same Pro subscription (via universal purchase on the Mac App Store). The goal is to let Pro users take full advantage of sync by writing on Mac and capturing on iPhone, and to make Haven more appealing as a cross-platform notes ecosystem.

## Goals

1. **Full-featured companion** -- Same capabilities as iOS, optimized for desktop (keyboard-first workflow, multi-window, resizable columns)
2. **Native Mac feel** -- Three-column layout, standard menu bar, system keyboard shortcuts, NSTextView editor. Not a Catalyst port.
3. **Quick Note** -- Global hotkey for instant capture from anywhere on the Mac
4. **Universal purchase** -- One Pro subscription covers iOS and macOS via Mac App Store
5. **Minimal codebase divergence** -- Share ~90% of Swift files. Platform-specific code isolated behind `#if os()` guards.

## Non-Goals (v1)

- Menu bar status item / widget
- Finder Quick Look extension for .haven files
- Handoff / Continuity Camera between iOS and Mac
- Spotlight / CoreSpotlight integration
- Touch Bar support (deprecated)
- Mac Catalyst (rejected in favor of native AppKit where needed)

---

## Architecture

### Project Structure

Same Xcode project, new macOS target added to `project.yml` (XcodeGen).

```
Haven/
├── project.yml              # Updated: new HavenMac target
├── Haven/                   # Shared + iOS source
│   ├── App/                 # HavenApp.swift (shared entry point)
│   ├── Models/              # 100% shared
│   ├── Services/            # 100% shared (except editor)
│   │   ├── Database/        # Shared (SQLite3 cross-platform)
│   │   ├── Sync/            # Shared (URLSession cross-platform)
│   │   ├── Encryption/      # Shared (CryptoKit cross-platform)
│   │   ├── Subscription/    # Shared (StoreKit 2 cross-platform)
│   │   └── Editor/          # Conditional compilation
│   │       ├── MarkdownHighlighter.swift  # #if os() for font/color types
│   │       ├── RichTextCoordinator.swift  # iOS only (UITextView)
│   │       └── MacTextViewCoordinator.swift  # macOS only (NSTextView)
│   ├── Views/               # Mostly shared (SwiftUI)
│   │   └── NoteEditor/
│   │       ├── NoteEditorView.swift  # Conditional: wraps platform editor
│   │       └── MacEditorView.swift   # macOS NSViewRepresentable
│   ├── Mac/                 # macOS-only files
│   │   ├── QuickNotePanel.swift      # NSPanel for global capture
│   │   ├── QuickNoteWindow.swift     # Window controller
│   │   ├── MacMenuCommands.swift     # SwiftUI .commands modifier
│   │   └── GlobalHotkey.swift        # Carbon/Accessibility hotkey
│   ├── Protocols/           # 100% shared
│   ├── Utilities/           # 100% shared
│   └── Extensions/          # 100% shared
├── HavenWidget/             # Shared (WidgetKit works on macOS)
└── HavenTests/              # Shared
```

### Target Configuration (project.yml additions)

```yaml
HavenMac:
  type: application
  platform: macOS
  deploymentTarget: "14.0"
  sources:
    - path: Haven
      excludes:
        - "HavenWidget/**"
  settings:
    base:
      PRODUCT_BUNDLE_IDENTIFIER: com.havennotes.app
      PRODUCT_NAME: Haven
      MACOSX_DEPLOYMENT_TARGET: "14.0"
      COMBINE_HIDPI_IMAGES: true
  entitlements:
    path: Haven/HavenMac.entitlements
    properties:
      com.apple.security.app-sandbox: true
      com.apple.security.files.user-selected.read-write: true
      com.apple.application-identifier: $(TeamIdentifierPrefix)com.havennotes.app
```

- **macOS 14.0** deployment target (matches iOS 17 feature parity for SwiftUI, StoreKit 2)
- **Same bundle ID** (`com.havennotes.app`) for universal purchase
- **App Sandbox** enabled for Mac App Store

### File Sharing Strategy

| Category | Files | Shared? | Notes |
|----------|-------|---------|-------|
| Models | 8 | 100% | Pure Swift structs |
| Database | 7 | 100% | SQLite3 is cross-platform |
| Sync | 4 | 100% | URLSession cross-platform |
| Encryption | 1 | 100% | CryptoKit cross-platform |
| Subscription | 1 | 100% | StoreKit 2 cross-platform |
| Protocols | 7 | 100% | Pure Swift |
| Utilities | 5 | 100% | Foundation only |
| Extensions | 4 | 100% | SwiftUI + Foundation |
| Views (SwiftUI) | 32 | ~95% | Minor `#if os()` for platform idioms |
| Editor | 3 | Conditional | UITextView (iOS) / NSTextView (macOS) |
| BiometricService | 1 | Conditional | Touch ID on Mac, Face ID on iOS |
| SpeechRecognizer | 1 | Conditional | Available on both, minor API diffs |
| ToastManager | 1 | Conditional | UIAccessibility vs NSAccessibility |
| Mac-specific | 4 | macOS only | Quick Note, menus, hotkey |

---

## Window Layout

### Main Window -- Three-Column NavigationSplitView

```
┌─────────────────────────────────────────────────────────────┐
│  ◉ ◉ ◉  │          Haven — Meeting Notes            │      │
├──────────┼─────────────────┼────────────────────────────────┤
│ Haven    │  All Notes (12) │                                │
│          │                 │  Meeting Notes                  │
│ ─────── │  ┌────────────┐ │  📁 Work · 2 min ago           │
│ 📝 All   │  │Meeting Note│ │                                │
│ 📅 Daily │  │Q2 roadmap..│ │  # Q2 Roadmap                  │
│ 🔍 Search│  │2 min ago   │ │                                │
│ 🕸 Graph │  └────────────┘ │  Discussed the quarterly       │
│          │  Project Ideas  │  goals with the team...        │
│ FOLDERS  │  A calm space.. │                                │
│ 📁 Work  │  1 hour ago     │  - Launch desktop app          │
│ 📁 Personal│               │  - Improve sync reliability    │
│          │  Reading List   │  - Add [[Project Ideas]]       │
│ TAGS     │  Books to read..│                                │
│ # ideas  │  3 hours ago    │  ## Action Items               │
│ # planning│                │  ☐ Draft PRD for desktop       │
│          │                 │  ☑ Review sync architecture    │
│ ─────── │                 │                                │
│ ⚙ Settings│                │                                │
└──────────┴─────────────────┴────────────────────────────────┘
```

**Column widths:**
- Sidebar: 200px default, 160px min, 260px max
- Note list: 260px default, 220px min, 360px max
- Editor: fills remaining space, 400px min

**Behaviors:**
- Columns resizable by dragging dividers
- Sidebar toggleable via Cmd+0 or View menu
- Note list toggleable via Cmd+Shift+L
- Double-click a note to open in a new window
- Window state (size, column widths, position) persisted via `NSWindowRestoration`

### Secondary Windows

- Notes opened via Cmd+double-click get their own `NSWindow`
- Editor-only view (no sidebar, no list)
- Title bar shows note title
- Standard macOS window controls (minimize, zoom, close)
- Multiple notes can be open simultaneously

---

## Editor -- NSTextView

### MacTextViewCoordinator

Mirrors `RichTextCoordinator` (iOS) but uses `NSTextView`:

```
NSViewRepresentable (MacEditorView)
  └── Coordinator (MacTextViewCoordinator)
        ├── NSTextView (the text view)
        ├── NSTextViewDelegate (text changes, selection)
        ├── MarkdownHighlighter (shared, #if os for font/color)
        └── NSPopover (wiki-link autocomplete)
```

**Key differences from iOS:**
- `NSTextView` instead of `UITextView`
- `NSFont` / `NSColor` instead of `UIFont` / `UIColor`
- `NSPopover` for wiki-link autocomplete instead of overlay (properly anchored to cursor rect)
- No toolbar overlay -- formatting via menu bar + keyboard shortcuts
- `NSTextView` natively supports undo/redo, spellcheck, services menu, text replacement
- `NSScrollView` wrapping (NSTextView requires it, unlike UITextView)

### MarkdownHighlighter -- Conditional Compilation

```swift
#if os(iOS)
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#elseif os(macOS)
import AppKit
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#endif

struct MarkdownHighlighter {
    // All logic uses PlatformFont and PlatformColor
    // Theme struct uses type aliases
    // Regex patterns and highlighting logic are 100% shared
}
```

### Keyboard Shortcuts (Editor)

| Shortcut | Action |
|----------|--------|
| Cmd+B | Toggle bold |
| Cmd+I | Toggle italic |
| Cmd+K | Insert wiki link `[[]]` |
| Cmd+Shift+H | Toggle heading |
| Cmd+Shift+L | Toggle list |
| Cmd+Shift+C | Toggle code block |
| Cmd+Shift+T | Toggle task checkbox |
| Cmd+/ | Toggle comment/strikethrough |

Implemented via `NSTextView.performKeyEquivalent()` override or SwiftUI `.commands` modifier.

---

## Quick Note

### Concept

A global hotkey (Cmd+Shift+N) summons a small floating window from anywhere on the Mac -- even when Haven is in the background or not running. The user types a quick thought, hits Cmd+Enter to save (or Escape to discard), and it disappears. The note lands in All Notes.

### Implementation

```
GlobalHotkey (Carbon RegisterEventHotKey or Accessibility API)
  └── QuickNotePanel (NSPanel, .floating, .nonactivating)
        ├── NSTextField (title, optional)
        ├── NSTextView (body, auto-focused)
        ├── Folder picker (dropdown, defaults to none)
        └── Save button (Cmd+Enter) / Discard (Escape)
```

**NSPanel properties:**
- `level: .floating` -- stays above other windows
- `styleMask: [.titled, .closable, .resizable, .utilityWindow]`
- `isMovableByWindowBackground: true`
- `hidesOnDeactivate: false` -- stays visible when Haven loses focus
- Size: 480x320px, centered on screen
- Appearance: matches system dark/light mode, Haven color palette

**Hotkey registration:**
- Uses `Carbon.RegisterEventHotKey` (still the most reliable API for global hotkeys on macOS)
- Falls back to `Accessibility` API if needed
- User-configurable in Settings (v2)
- Requires Accessibility permission on first use

**Save behavior:**
1. Creates a new Note via `NoteRepository.upsert()`
2. If sync is enabled + connected, triggers immediate sync
3. Panel fades out with animation
4. Shows a brief system notification: "Note saved" (optional, via `UNUserNotificationCenter`)

---

## Menu Bar

### Structure

```
Haven
├── About Haven
├── Settings... (Cmd+,)
├── ─────────
└── Quit Haven (Cmd+Q)

File
├── New Note (Cmd+N)
├── New Daily Note (Cmd+Shift+D)
├── Quick Note (Cmd+Shift+N)
├── ─────────
├── Close Window (Cmd+W)
└── Close All (Cmd+Option+W)

Edit
├── Undo (Cmd+Z)
├── Redo (Cmd+Shift+Z)
├── ─────────
├── Cut / Copy / Paste (standard)
├── ─────────
├── Bold (Cmd+B)
├── Italic (Cmd+I)
├── Heading (Cmd+Shift+H)
├── Link (Cmd+K)
├── List (Cmd+Shift+L)
├── Task (Cmd+Shift+T)
├── Code (Cmd+Shift+C)
├── ─────────
├── Find... (Cmd+F)
└── Find in All Notes (Cmd+Shift+F)

View
├── Toggle Sidebar (Cmd+0)
├── Toggle Note List (Cmd+Shift+L)
├── ─────────
├── Knowledge Graph (Cmd+G)
├── ─────────
└── Enter Full Screen (Cmd+Ctrl+F)

Window
├── Minimize (Cmd+M)
├── Zoom
├── ─────────
└── [open windows list]
```

Implemented via SwiftUI `.commands { }` modifier on `WindowGroup`.

---

## Platform-Specific Adaptations

### BiometricService

```swift
#if os(iOS)
// Face ID + Touch ID, LAContext with .deviceOwnerAuthenticationWithBiometrics
// Falls back to passcode
#elseif os(macOS)
// Touch ID (MacBook Pro/Air) or Apple Watch unlock
// LAContext with .deviceOwnerAuthenticationWithBiometrics
// Falls back to system password
// No Face ID on Mac
#endif
```

The `LAContext` API is the same on both platforms. The only difference is the biometry type check and the fallback description text.

### Lock Screen

- **iOS:** Full-screen overlay with Haven logo, biometric prompt
- **macOS:** Window-level modal sheet over the main window. Standard macOS password/Touch ID dialog. Cannot be bypassed by switching windows (all Haven windows are locked).

### Settings

- **iOS:** In-app Settings view with navigation stack
- **macOS:** Standard `Settings` window (SwiftUI `Settings { }` scene). Tabs: General, Sync, Encryption, Subscription, About.

### Notifications

- **iOS:** Local notifications via `UNUserNotificationCenter`
- **macOS:** Same API (available on macOS). Used for sync completion, Quick Note save confirmation.

### App Lifecycle

- **iOS:** `scenePhase` for foreground/background transitions
- **macOS:** Same SwiftUI `scenePhase` + `NSApplication.willTerminate` for cleanup. Haven stays running when all windows are closed (standard Mac behavior). Reopens main window via Dock click.

---

## Data & Sync

No changes needed. The entire data layer is cross-platform:

- **SQLite3** database at the same relative path (`Documents/haven.db`)
- **Same schema**, same migrations, same WAL mode
- **Same sync protocol** -- the Mac and iPhone sync to the same server
- **Same encryption** -- AES-GCM via CryptoKit, keys in macOS Keychain
- **Conflict resolution** -- Same last-write-wins strategy

The only consideration: if both Mac and iPhone are online simultaneously, both will poll the sync server every 5 minutes. The existing conflict resolution handles this correctly.

---

## Distribution

- **Mac App Store** only (v1)
- **Universal purchase** via same bundle ID (`com.havennotes.app`) and App Store Connect configuration
- **Same subscription products**: `com.haven.pro.monthly`, `com.haven.pro.yearly`
- **macOS 14.0+** deployment target
- **App Sandbox** enabled with:
  - `com.apple.security.files.user-selected.read-write` (Notion import file picker)
  - Network access (sync)

---

## Testing Strategy

- **Shared unit tests** run on both iOS and macOS destinations
- **macOS UI tests** for: three-column navigation, keyboard shortcuts, Quick Note panel
- **Manual testing**: sync between iOS Simulator and macOS app running side-by-side

---

## Estimated Scope

| Work Item | Effort | Priority |
|-----------|--------|----------|
| project.yml macOS target + build | S | P0 |
| `#if os()` guards on 6 existing files | S | P0 |
| `MacTextViewCoordinator` (NSTextView) | L | P0 |
| `MacEditorView` (NSViewRepresentable) | M | P0 |
| `MacMenuCommands` (SwiftUI .commands) | M | P0 |
| Keyboard shortcuts in editor | M | P0 |
| Settings scene (macOS tabs) | M | P0 |
| Lock screen adaptation (sheet) | S | P0 |
| Window restoration + multi-window | M | P1 |
| Quick Note panel + global hotkey | L | P1 |
| WidgetKit macOS adaptation | S | P2 |
| Polish + platform-specific testing | L | P0 |

**Total estimated effort:** ~2-3 weeks of focused work.
