# Haven for Mac Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native macOS target to Haven that shares ~90% of the iOS codebase, with a three-column layout, NSTextView-based editor, keyboard shortcuts, and a Quick Note global hotkey.

**Architecture:** Same Xcode project (project.yml), new macOS target. Shared code via conditional compilation (`#if os(iOS)` / `#if os(macOS)`). Platform-specific code isolated to 6 existing files (type aliases + guards) and 4 new macOS-only files (NSTextView coordinator, Quick Note panel, menu commands, global hotkey).

**Tech Stack:** SwiftUI (shared views), AppKit (NSTextView, NSPanel, global hotkey), SQLite3, CryptoKit, StoreKit 2, LocalAuthentication — all Apple frameworks, zero external deps.

**Spec:** `docs/superpowers/specs/2026-04-23-haven-macos-design.md`

---

## File Map

### Files to Create

| File | Purpose |
|------|---------|
| `Haven/Mac/MacEditorView.swift` | NSViewRepresentable wrapping NSTextView for macOS editor |
| `Haven/Mac/MacTextViewCoordinator.swift` | NSTextViewDelegate coordinator mirroring RichTextCoordinator |
| `Haven/Mac/MacMenuCommands.swift` | SwiftUI `.commands` for File/Edit/View menus |
| `Haven/Mac/QuickNotePanel.swift` | NSPanel + NSViewController for floating Quick Note |
| `Haven/Mac/GlobalHotkey.swift` | Carbon RegisterEventHotKey for Cmd+Shift+N |
| `Haven/Mac/MacSettingsView.swift` | macOS Settings scene with tabs |
| `Haven/HavenMac.entitlements` | macOS sandbox entitlements |
| `Haven/MacInfo.plist` | macOS-specific Info.plist properties |

### Files to Modify (Conditional Compilation)

| File | Change |
|------|--------|
| `project.yml` | Add HavenMac target |
| `Haven/Services/Editor/MarkdownHighlighter.swift` | `#if os` type aliases for UIFont/UIColor vs NSFont/NSColor |
| `Haven/Extensions/Color+Haven.swift` | `#if os` for UIColor vs NSColor trait closures |
| `Haven/Views/Shared/ToastManager.swift` | `#if os` for UIAccessibility vs NSAccessibility |
| `Haven/Services/Security/BiometricService.swift` | `#if os` for Face ID description text |
| `Haven/Services/Editor/SpeechRecognizer.swift` | `#if os(iOS)` guard (exclude from macOS v1) |
| `Haven/App/HavenApp.swift` | Add macOS Settings scene, Quick Note window, platform guards |
| `Haven/Views/NoteEditor/NoteEditorView.swift` | `#if os` to use MacEditorView vs RichTextEditor |
| `Haven/Views/NoteEditor/EditorToolbarView.swift` | `#if os(iOS)` — toolbar only on iOS; macOS uses menu bar |

---

## Task 1: Add macOS target to project.yml

**Files:**
- Modify: `project.yml`
- Create: `Haven/HavenMac.entitlements`

- [ ] **Step 1: Create macOS entitlements file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

Write this to `Haven/HavenMac.entitlements`.

- [ ] **Step 2: Add HavenMac target to project.yml**

Add after the existing `Haven` target (before `HavenWidgetExtension`):

```yaml
  HavenMac:
    type: application
    platform: macOS
    deploymentTarget: "14.0"
    sources:
      - path: Haven
        excludes:
          - "**/*.md"
          - "**/*.sql"
          - "HavenWidget/**"
    resources:
      - path: Haven/Assets.xcassets
      - path: Haven/PrivacyInfo.xcprivacy
      - path: Haven/Configuration.storekit
    scheme:
      storeKitConfiguration: Haven/Configuration.storekit
    info:
      path: Haven/MacInfo.plist
      properties:
        CFBundleDisplayName: Haven
        CFBundleShortVersionString: "1.1"
        CFBundleVersion: "3"
        CFBundleURLTypes:
          - CFBundleURLName: com.havennotes.app
            CFBundleURLSchemes:
              - haven
        LSApplicationCategoryType: public.app-category.productivity
    entitlements:
      path: Haven/HavenMac.entitlements
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.havennotes.app
        SWIFT_VERSION: 5.9
        MACOSX_DEPLOYMENT_TARGET: "14.0"
        COMBINE_HIDPI_IMAGES: YES
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor
        INFOPLIST_FILE: Haven/MacInfo.plist
        CODE_SIGN_ENTITLEMENTS: Haven/HavenMac.entitlements
```

Also update the top-level `options` to include macOS deployment target:

```yaml
options:
  bundleIdPrefix: com.haven
  deploymentTarget:
    iOS: "17.0"
    macOS: "14.0"
```

And add macOS to the base settings:

```yaml
settings:
  base:
    SWIFT_VERSION: 5.9
    IPHONEOS_DEPLOYMENT_TARGET: "17.0"
    MACOSX_DEPLOYMENT_TARGET: "14.0"
    ENABLE_BITCODE: NO
```

- [ ] **Step 3: Create MacInfo.plist placeholder**

Create `Haven/MacInfo.plist` — XcodeGen will populate it from the `info.properties` in project.yml, but we need the file to exist:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict/>
</plist>
```

- [ ] **Step 4: Create Mac directory**

```bash
mkdir -p Haven/Mac
```

- [ ] **Step 5: Generate and verify project**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven && xcodegen generate
```

Expected: Project generates with both Haven (iOS) and HavenMac (macOS) targets. Build will fail at this point because of UIKit imports in shared files — that's expected and fixed in subsequent tasks.

- [ ] **Step 6: Commit**

```bash
git add project.yml Haven/HavenMac.entitlements Haven/MacInfo.plist Haven/Mac/
git commit -m "feat(mac): add macOS target to project.yml with entitlements and Info.plist"
```

---

## Task 2: Add platform type aliases and conditional compilation guards

**Files:**
- Modify: `Haven/Services/Editor/MarkdownHighlighter.swift`
- Modify: `Haven/Extensions/Color+Haven.swift`
- Modify: `Haven/Views/Shared/ToastManager.swift`
- Modify: `Haven/Services/Security/BiometricService.swift`
- Modify: `Haven/Services/Editor/SpeechRecognizer.swift`

- [ ] **Step 1: Add platform type aliases to MarkdownHighlighter**

Replace the `import UIKit` at the top of `Haven/Services/Editor/MarkdownHighlighter.swift` with:

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
```

Then replace all occurrences in the file:
- `UIFont` → `PlatformFont`
- `UIColor` → `PlatformColor`
- `UITraitCollection` parameter in `Theme.haven(traitCollection:)` needs a platform guard:

Replace the `haven(traitCollection:)` method signature and body:

```swift
#if os(iOS)
static func haven(traitCollection: UITraitCollection) -> Theme {
    let isDark = traitCollection.userInterfaceStyle == .dark
#elseif os(macOS)
static func haven(appearance: NSAppearance? = NSAppearance.current) -> Theme {
    let isDark = appearance?.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
#endif
    let bodySize: CGFloat = PlatformFont.preferredFont(forTextStyle: .body).pointSize
    // ... rest of theme construction unchanged, using PlatformFont/PlatformColor
```

For macOS, `PlatformFont.preferredFont(forTextStyle:)` doesn't exist. Use:

```swift
#if os(iOS)
let bodySize: CGFloat = PlatformFont.preferredFont(forTextStyle: .body).pointSize
#elseif os(macOS)
let bodySize: CGFloat = NSFont.systemFontSize
#endif
```

And for font constructors, replace:
- `.preferredFont(forTextStyle: .body)` → `#if os(macOS) NSFont.systemFont(ofSize: NSFont.systemFontSize) #else ... #endif`
- `.systemFont(ofSize:weight:)` → same API on both platforms
- `.boldSystemFont(ofSize:)` → same API on both platforms
- `.monospacedSystemFont(ofSize:weight:)` → same API on both platforms

Also update `updateTheme()` method:

```swift
#if os(iOS)
func updateTheme(for traitCollection: UITraitCollection) {
    theme = Theme.haven(traitCollection: traitCollection)
}
#elseif os(macOS)
func updateTheme(for appearance: NSAppearance? = nil) {
    theme = Theme.haven(appearance: appearance)
}
#endif
```

- [ ] **Step 2: Add platform guards to Color+Haven.swift**

Replace `import SwiftUI` at top with:

```swift
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
```

Replace the `UIColor { trait in ... }` pattern throughout the file. Each color like:

```swift
static let havenPrimary = Color(UIColor { trait in
    trait.userInterfaceStyle == .dark
        ? UIColor(red: ..., alpha: 1)
        : UIColor(red: ..., alpha: 1)
})
```

becomes:

```swift
static let havenPrimary: Color = {
    #if os(iOS)
    return Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0xA0/255.0, green: 0x85/255.0, blue: 0x5E/255.0, alpha: 1)
            : UIColor(red: 0x8B/255.0, green: 0x6F/255.0, blue: 0x47/255.0, alpha: 1)
    })
    #elseif os(macOS)
    return Color(NSColor(name: nil) { appearance in
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return isDark
            ? NSColor(red: 0xA0/255.0, green: 0x85/255.0, blue: 0x5E/255.0, alpha: 1)
            : NSColor(red: 0x8B/255.0, green: 0x6F/255.0, blue: 0x47/255.0, alpha: 1)
    })
    #endif
}()
```

Apply this pattern to ALL color definitions in the file (havenPrimary, havenSecondary, havenAccent, havenBackground, havenSurface, havenTextPrimary, havenTextSecondary, etc.).

- [ ] **Step 3: Add platform guard to ToastManager**

Replace `import UIKit` with:

```swift
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
```

Replace the `UIAccessibility.post` call:

```swift
#if os(iOS)
UIAccessibility.post(notification: .announcement, argument: message)
#elseif os(macOS)
NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested, userInfo: [.announcement: message, .priority: NSAccessibilityPriorityLevel.high.rawValue])
#endif
```

- [ ] **Step 4: Add platform guard to BiometricService**

In `Haven/Services/Security/BiometricService.swift`, add at the top:

```swift
#if os(iOS)
import UIKit
#endif
```

In the `biometricType` computed property (or wherever Face ID is mentioned), add:

```swift
var biometricType: BiometricType {
    let context = LAContext()
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
        return .none
    }
    #if os(iOS)
    return context.biometryType == .faceID ? .faceID : .touchID
    #elseif os(macOS)
    return .touchID  // Mac only has Touch ID (or Apple Watch)
    #endif
}
```

- [ ] **Step 5: Exclude SpeechRecognizer from macOS**

Wrap the entire contents of `Haven/Services/Editor/SpeechRecognizer.swift` in:

```swift
#if os(iOS)
import Speech
import AVFoundation

@MainActor
final class SpeechRecognizer: ObservableObject {
    // ... entire existing implementation
}
#endif
```

On macOS, voice dictation is handled by the system (Fn+Fn or accessibility dictation). We'll provide a stub for compilation.

At the bottom of the file (outside the `#if`), add:

```swift
#if os(macOS)
import SwiftUI

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var isAvailable: Bool = false
    func startRecording() async {}
    func stopRecording() {}
}
#endif
```

- [ ] **Step 6: Build macOS target to verify compilation of shared code**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven && xcodegen generate && xcodebuild -project Haven.xcodeproj -scheme HavenMac -configuration Debug -destination "platform=macOS" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30
```

This will still fail because `RichTextEditor` (UIViewRepresentable) is used in `NoteEditorView.swift`. That's fixed in Task 3.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(mac): add platform type aliases and conditional compilation for macOS

- MarkdownHighlighter: PlatformFont/PlatformColor aliases
- Color+Haven: NSColor appearance-based variants
- ToastManager: NSAccessibility announcement
- BiometricService: macOS Touch ID only
- SpeechRecognizer: stub for macOS (system dictation)"
```

---

## Task 3: Build the macOS NSTextView editor

**Files:**
- Create: `Haven/Mac/MacEditorView.swift`
- Create: `Haven/Mac/MacTextViewCoordinator.swift`
- Modify: `Haven/Views/NoteEditor/NoteEditorView.swift`
- Modify: `Haven/Views/NoteEditor/EditorToolbarView.swift`

- [ ] **Step 1: Create MacTextViewCoordinator**

Create `Haven/Mac/MacTextViewCoordinator.swift`:

```swift
#if os(macOS)
import AppKit
import SwiftUI

final class MacTextViewCoordinator: NSObject, NSTextViewDelegate {
    var htmlContent: Binding<String>
    var onTextChanged: ((String) -> Void)?
    var onLinkTapped: ((String) -> Void)?
    weak var textView: NSTextView?

    private let highlighter = MarkdownHighlighter()
    private var isEditing = false
    private var highlightWorkItem: DispatchWorkItem?
    private let highlightDebounce: TimeInterval = 0.05
    @Published var activeFormats: Set<MarkdownFormat> = []

    init(htmlContent: Binding<String>,
         onTextChanged: ((String) -> Void)?,
         onLinkTapped: ((String) -> Void)?) {
        self.htmlContent = htmlContent
        self.onTextChanged = onTextChanged
        self.onLinkTapped = onLinkTapped
        super.init()
    }

    // MARK: - NSTextViewDelegate

    func textDidBeginEditing(_ notification: Notification) {
        isEditing = true
    }

    func textDidEndEditing(_ notification: Notification) {
        isEditing = false
        guard let tv = textView else { return }
        applyHighlighting(to: tv, text: tv.string)
    }

    func textDidChange(_ notification: Notification) {
        guard let tv = textView else { return }
        let text = tv.string
        htmlContent.wrappedValue = text
        onTextChanged?(text)
        detectActiveFormats(in: tv)

        // Debounced highlighting
        highlightWorkItem?.cancel()
        highlightWorkItem = DispatchWorkItem { [weak self] in
            guard let self, let tv = self.textView else { return }
            self.applyHighlighting(to: tv, text: tv.string)
        }
        if let workItem = highlightWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + highlightDebounce, execute: workItem)
        }
    }

    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        if let url = link as? URL {
            onLinkTapped?(url.absoluteString)
            return true
        }
        if let str = link as? String {
            onLinkTapped?(str)
            return true
        }
        return false
    }

    // MARK: - Highlighting

    func applyHighlighting(to textView: NSTextView, text: String) {
        let selectedRanges = textView.selectedRanges
        highlighter.updateTheme()
        highlighter.highlight(text: text, in: textView.textStorage!)
        textView.selectedRanges = selectedRanges
    }

    // MARK: - Formatting Actions

    func toggleBold() { wrapSelection(prefix: "**", suffix: "**") }
    func toggleItalic() { wrapSelection(prefix: "*", suffix: "*") }
    func toggleHeading() { toggleLinePrefix("# ") }
    func toggleList() { toggleLinePrefix("- ") }
    func toggleTask() { toggleLinePrefix("- [ ] ") }
    func toggleCode() { wrapSelection(prefix: "`", suffix: "`") }
    func insertWikiLink() { wrapSelection(prefix: "[[", suffix: "]]") }

    private func wrapSelection(prefix: String, suffix: String) {
        guard let tv = textView, let storage = tv.textStorage else { return }
        let range = tv.selectedRange()
        let selected = (storage.string as NSString).substring(with: range)
        let wrapped = "\(prefix)\(selected)\(suffix)"
        storage.replaceCharacters(in: range, with: wrapped)
        // Place cursor inside the wrapper if no text was selected
        if range.length == 0 {
            tv.setSelectedRange(NSRange(location: range.location + prefix.count, length: 0))
        }
        textDidChange(Notification(name: NSText.didChangeNotification, object: tv))
    }

    private func toggleLinePrefix(_ prefix: String) {
        guard let tv = textView, let storage = tv.textStorage else { return }
        let text = storage.string as NSString
        let lineRange = text.lineRange(for: tv.selectedRange())
        let line = text.substring(with: lineRange)

        if line.hasPrefix(prefix) {
            let trimmed = String(line.dropFirst(prefix.count))
            storage.replaceCharacters(in: lineRange, with: trimmed)
        } else {
            let prefixed = prefix + line
            storage.replaceCharacters(in: lineRange, with: prefixed)
        }
        textDidChange(Notification(name: NSText.didChangeNotification, object: tv))
    }

    private func detectActiveFormats(in textView: NSTextView) {
        let text = textView.string as NSString
        let cursorPos = textView.selectedRange().location
        guard cursorPos <= text.length else { return }
        let lineRange = text.lineRange(for: NSRange(location: cursorPos, length: 0))
        let line = text.substring(with: lineRange)

        var formats = Set<MarkdownFormat>()
        if line.hasPrefix("# ") || line.hasPrefix("## ") || line.hasPrefix("### ") { formats.insert(.heading) }
        if line.hasPrefix("- ") || line.hasPrefix("* ") { formats.insert(.list) }
        // Check for bold/italic around cursor
        let beforeCursor = text.substring(to: cursorPos)
        let boldCount = beforeCursor.components(separatedBy: "**").count - 1
        if boldCount % 2 == 1 { formats.insert(.bold) }
        let italicCount = beforeCursor.components(separatedBy: "*").count - 1 - (boldCount * 2)
        if italicCount % 2 == 1 { formats.insert(.italic) }
        activeFormats = formats
    }
}
#endif
```

- [ ] **Step 2: Create MacEditorView (NSViewRepresentable)**

Create `Haven/Mac/MacEditorView.swift`:

```swift
#if os(macOS)
import SwiftUI
import AppKit

struct MacEditorView: NSViewRepresentable {
    @Binding var htmlContent: String
    var onLinkTapped: ((String) -> Void)?
    var onTextChanged: ((String) -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    class Shared: ObservableObject {
        weak var coordinator: MacTextViewCoordinator?
        @Published var activeFormats: Set<MarkdownFormat> = []
    }

    var shared: Shared?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.drawsBackground = false
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textColor = NSColor(Color.havenTextPrimary)
        textView.insertionPointColor = NSColor(Color.havenAccent)
        textView.textContainerInset = NSSize(width: 0, height: 12)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false

        // Auto-resize
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        scrollView.documentView = textView
        context.coordinator.textView = textView
        shared?.coordinator = context.coordinator

        if !htmlContent.isEmpty {
            textView.string = htmlContent
            context.coordinator.applyHighlighting(to: textView, text: htmlContent)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if context.coordinator.isEditing { return }

        if textView.string != htmlContent {
            textView.string = htmlContent
            context.coordinator.applyHighlighting(to: textView, text: htmlContent)
        }

        // Update active formats binding
        if let shared = shared {
            shared.activeFormats = context.coordinator.activeFormats
        }
    }

    func makeCoordinator() -> MacTextViewCoordinator {
        MacTextViewCoordinator(
            htmlContent: $htmlContent,
            onTextChanged: onTextChanged,
            onLinkTapped: onLinkTapped
        )
    }
}
#endif
```

- [ ] **Step 3: Add platform guard to NoteEditorView**

In `Haven/Views/NoteEditor/NoteEditorView.swift`, find the `RichTextEditor` usage and wrap it:

At the top of the file, add the macOS shared state:

```swift
#if os(iOS)
@StateObject private var editorShared = RichTextEditor.Shared()
#elseif os(macOS)
@StateObject private var editorShared = MacEditorView.Shared()
#endif
```

Where `RichTextEditor` is instantiated in the body, wrap it:

```swift
#if os(iOS)
RichTextEditor(
    htmlContent: Binding(
        get: { viewModel.note.bodyHTML },
        set: { viewModel.updateBody($0) }
    ),
    onLinkTapped: { link in viewModel.handleLink(link) },
    onTextChanged: { text in viewModel.onTextChanged(text) },
    shared: editorShared
)
#elseif os(macOS)
MacEditorView(
    htmlContent: Binding(
        get: { viewModel.note.bodyHTML },
        set: { viewModel.updateBody($0) }
    ),
    onLinkTapped: { link in viewModel.handleLink(link) },
    onTextChanged: { text in viewModel.onTextChanged(text) },
    shared: editorShared
)
#endif
```

- [ ] **Step 4: Guard EditorToolbarView for iOS only**

In `Haven/Views/NoteEditor/EditorToolbarView.swift`, wrap the entire content in `#if os(iOS)` since macOS uses the menu bar for formatting:

```swift
#if os(iOS)
import SwiftUI

struct EditorToolbarView: View {
    // ... entire existing implementation
}
#endif
```

Then in `NoteEditorView.swift`, wrap the `EditorToolbarView` usage:

```swift
#if os(iOS)
EditorToolbarView(...)
#endif
```

- [ ] **Step 5: Guard dictation UI for iOS only**

In `NoteEditorView.swift`, wrap the dictation recording banner and microphone toolbar button references with `#if os(iOS)`:

```swift
#if os(iOS)
// Dictation recording banner
if viewModel.isRecording {
    // ... recording banner UI
}
#endif
```

- [ ] **Step 6: Build macOS target**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven && xcodegen generate && xcodebuild -project Haven.xcodeproj -scheme HavenMac -configuration Debug -destination "platform=macOS" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30
```

Expected: BUILD SUCCEEDED. The macOS app should launch with three-column layout (NavigationSplitView already handles this for regular size class) and the NSTextView editor.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat(mac): add NSTextView editor and platform guards for macOS

- MacEditorView: NSViewRepresentable wrapping NSTextView
- MacTextViewCoordinator: NSTextViewDelegate with formatting actions
- NoteEditorView: conditional compilation for iOS/macOS editors
- EditorToolbarView: iOS-only (macOS uses menu bar)
- SpeechRecognizer: stub on macOS"
```

---

## Task 4: Add macOS menu bar and keyboard shortcuts

**Files:**
- Create: `Haven/Mac/MacMenuCommands.swift`
- Modify: `Haven/App/HavenApp.swift`

- [ ] **Step 1: Create MacMenuCommands**

Create `Haven/Mac/MacMenuCommands.swift`:

```swift
#if os(macOS)
import SwiftUI

struct HavenMenuCommands: Commands {
    @FocusedValue(\.activeEditor) var activeEditor: MacTextViewCoordinator?

    var body: some Commands {
        // Replace default New Item
        CommandGroup(replacing: .newItem) {
            Button("New Note") {
                NotificationCenter.default.post(name: .havenNewNote, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Daily Note") {
                NotificationCenter.default.post(name: .havenDailyNote, object: nil)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Divider()

            Button("Quick Note") {
                NotificationCenter.default.post(name: .havenQuickNote, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        // Text formatting
        CommandMenu("Format") {
            Button("Bold") { activeEditor?.toggleBold() }
                .keyboardShortcut("b", modifiers: .command)

            Button("Italic") { activeEditor?.toggleItalic() }
                .keyboardShortcut("i", modifiers: .command)

            Divider()

            Button("Heading") { activeEditor?.toggleHeading() }
                .keyboardShortcut("h", modifiers: [.command, .shift])

            Button("List") { activeEditor?.toggleList() }
                .keyboardShortcut("l", modifiers: [.command, .shift])

            Button("Task") { activeEditor?.toggleTask() }
                .keyboardShortcut("t", modifiers: [.command, .shift])

            Button("Code") { activeEditor?.toggleCode() }
                .keyboardShortcut("c", modifiers: [.command, .shift])

            Divider()

            Button("Wiki Link") { activeEditor?.insertWikiLink() }
                .keyboardShortcut("k", modifiers: .command)
        }

        // View commands
        CommandGroup(after: .sidebar) {
            Button("Knowledge Graph") {
                NotificationCenter.default.post(name: .havenShowGraph, object: nil)
            }
            .keyboardShortcut("g", modifiers: .command)
        }

        // Search
        CommandGroup(replacing: .textEditing) {}
        CommandGroup(after: .textEditing) {
            Button("Find in All Notes") {
                NotificationCenter.default.post(name: .havenSearch, object: nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        }
    }
}

// MARK: - FocusedValue for active editor

struct ActiveEditorKey: FocusedValueKey {
    typealias Value = MacTextViewCoordinator
}

extension FocusedValues {
    var activeEditor: MacTextViewCoordinator? {
        get { self[ActiveEditorKey.self] }
        set { self[ActiveEditorKey.self] = newValue }
    }
}

// MARK: - Notification names

extension Notification.Name {
    static let havenNewNote = Notification.Name("havenNewNote")
    static let havenDailyNote = Notification.Name("havenDailyNote")
    static let havenQuickNote = Notification.Name("havenQuickNote")
    static let havenShowGraph = Notification.Name("havenShowGraph")
    static let havenSearch = Notification.Name("havenSearch")
}
#endif
```

- [ ] **Step 2: Wire commands into HavenApp**

In `Haven/App/HavenApp.swift`, add the commands modifier to the `WindowGroup`:

```swift
var body: some Scene {
    WindowGroup {
        // ... existing content view
    }
    #if os(macOS)
    .commands {
        HavenMenuCommands()
    }
    #endif

    #if os(macOS)
    Settings {
        MacSettingsView()
            .environmentObject(container)
    }
    #endif
}
```

Also add notification observers in `HavenNavigationStack` or the main content view to handle the menu notifications (`.havenNewNote`, `.havenDailyNote`, `.havenSearch`, `.havenShowGraph`). Wire these to the existing navigation actions:

```swift
#if os(macOS)
.onReceive(NotificationCenter.default.publisher(for: .havenNewNote)) { _ in
    viewModel.createNewNote()
}
.onReceive(NotificationCenter.default.publisher(for: .havenDailyNote)) { _ in
    // trigger daily note creation
}
.onReceive(NotificationCenter.default.publisher(for: .havenSearch)) { _ in
    appState.navigateTo(.search)
}
.onReceive(NotificationCenter.default.publisher(for: .havenShowGraph)) { _ in
    appState.navigateTo(.graph)
}
#endif
```

- [ ] **Step 3: Add FocusedValue to MacEditorView**

In `Haven/Mac/MacEditorView.swift`, the parent `NoteEditorView` should expose the coordinator via `.focusedValue`:

Add to `NoteEditorView.swift` body (macOS path):

```swift
#if os(macOS)
.focusedValue(\.activeEditor, editorShared.coordinator)
#endif
```

- [ ] **Step 4: Build and verify**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven && xcodegen generate && xcodebuild -project Haven.xcodeproj -scheme HavenMac -configuration Debug -destination "platform=macOS" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -15
```

Expected: BUILD SUCCEEDED. Menu bar shows Haven, File (with New Note shortcuts), Format (with Bold/Italic shortcuts), View (with Graph).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(mac): add menu bar commands and keyboard shortcuts

- File: New Note (Cmd+N), Daily Note (Cmd+Shift+D), Quick Note (Cmd+Shift+N)
- Format: Bold, Italic, Heading, List, Task, Code, Wiki Link
- View: Knowledge Graph (Cmd+G)
- Find in All Notes (Cmd+Shift+F)
- FocusedValue for active editor coordinator"
```

---

## Task 5: Build macOS Settings scene

**Files:**
- Create: `Haven/Mac/MacSettingsView.swift`

- [ ] **Step 1: Create MacSettingsView**

Create `Haven/Mac/MacSettingsView.swift`:

```swift
#if os(macOS)
import SwiftUI

struct MacSettingsView: View {
    @EnvironmentObject var container: DependencyContainer

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .environmentObject(container)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            SyncSettingsView()
                .environmentObject(container)
                .tabItem {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }

            EncryptionSettingsView()
                .environmentObject(container)
                .tabItem {
                    Label("Encryption", systemImage: "lock.shield")
                }

            SubscriptionView()
                .environmentObject(container)
                .tabItem {
                    Label("Subscription", systemImage: "star")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsTab: View {
    @EnvironmentObject var container: DependencyContainer
    @AppStorage("preferredTheme") private var preferredTheme = "system"

    var body: some View {
        Form {
            Picker("Appearance", selection: $preferredTheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)

            Section("Security") {
                Toggle("Lock Haven with Touch ID", isOn: Binding(
                    get: { container.biometricService.isEnabled },
                    set: { container.biometricService.setEnabled($0) }
                ))
            }
        }
        .padding()
    }
}
#endif
```

- [ ] **Step 2: Wire into HavenApp.swift**

Already done in Task 4 Step 2 — the `Settings { MacSettingsView() }` scene was added. Verify it's present.

- [ ] **Step 3: Build and verify**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven && xcodegen generate && xcodebuild -project Haven.xcodeproj -scheme HavenMac -configuration Debug -destination "platform=macOS" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -15
```

- [ ] **Step 4: Commit**

```bash
git add Haven/Mac/MacSettingsView.swift
git commit -m "feat(mac): add macOS Settings scene with General, Sync, Encryption, Subscription tabs"
```

---

## Task 6: Build Quick Note panel with global hotkey

**Files:**
- Create: `Haven/Mac/QuickNotePanel.swift`
- Create: `Haven/Mac/GlobalHotkey.swift`
- Modify: `Haven/App/HavenApp.swift`

- [ ] **Step 1: Create QuickNotePanel**

Create `Haven/Mac/QuickNotePanel.swift`:

```swift
#if os(macOS)
import SwiftUI
import AppKit

class QuickNotePanelController: NSObject, ObservableObject {
    private var panel: NSPanel?
    @Published var isVisible = false

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        if panel == nil {
            createPanel()
        }
        panel?.center()
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isVisible = true
    }

    func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "Quick Note"
        panel.level = .floating
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.minSize = NSSize(width: 360, height: 240)

        self.panel = panel
    }

    func setContent(_ view: some View) {
        let hostingView = NSHostingView(rootView: view)
        panel?.contentView = hostingView
    }
}

struct QuickNoteView: View {
    @State private var title = ""
    @State private var body = ""
    @FocusState private var bodyFocused: Bool
    var onSave: (String, String) -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(Color.havenPrimary)
                Text("Quick Note")
                    .font(.havenHeadline)
                    .foregroundColor(Color.havenTextPrimary)
                Spacer()
                Text("⌘⏎ Save")
                    .font(.caption)
                    .foregroundColor(Color.havenTextSecondary)
            }
            .padding(.bottom, Spacing.xs)

            // Title
            TextField("Title (optional)", text: $title)
                .textFieldStyle(.plain)
                .font(.havenBody.weight(.medium))
                .foregroundColor(Color.havenTextPrimary)

            Divider()

            // Body
            TextEditor(text: $body)
                .font(.havenBody)
                .foregroundColor(Color.havenTextPrimary)
                .scrollContentBackground(.hidden)
                .focused($bodyFocused)
                .frame(minHeight: 120)

            Spacer()

            // Actions
            HStack {
                Button("Discard") { onDismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.havenPrimary)
                    .disabled(body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(Spacing.xl)
        .frame(minWidth: 360, minHeight: 240)
        .background(Color.havenBackground)
        .onAppear { bodyFocused = true }
    }

    private func save() {
        let noteTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !noteBody.isEmpty else { return }
        onSave(noteTitle.isEmpty ? "Quick Note" : noteTitle, noteBody)
    }
}
#endif
```

- [ ] **Step 2: Create GlobalHotkey**

Create `Haven/Mac/GlobalHotkey.swift`:

```swift
#if os(macOS)
import Carbon
import AppKit

final class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var onTrigger: (() -> Void)?

    private init() {}

    func register(keyCode: UInt32 = UInt32(kVK_ANSI_N),
                  modifiers: UInt32 = UInt32(cmdKey | shiftKey),
                  handler: @escaping () -> Void) {
        onTrigger = handler

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4856_4E51) // "HVNQ" — HaVeN Quick
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        // Install handler
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                GlobalHotkeyManager.shared.onTrigger?()
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    deinit {
        unregister()
    }
}
#endif
```

- [ ] **Step 3: Wire Quick Note into HavenApp**

In `Haven/App/HavenApp.swift`, add Quick Note handling:

```swift
#if os(macOS)
@StateObject private var quickNotePanelController = QuickNotePanelController()
#endif
```

In the `init()` or `.onAppear` of the main window:

```swift
#if os(macOS)
// Register global hotkey for Quick Note
GlobalHotkeyManager.shared.register {
    DispatchQueue.main.async {
        quickNotePanelController.toggle()
    }
}

// Wire the notification from menu bar
NotificationCenter.default.addObserver(forName: .havenQuickNote, object: nil, queue: .main) { _ in
    quickNotePanelController.toggle()
}

// Set up the Quick Note panel content
quickNotePanelController.setContent(
    QuickNoteView(
        onSave: { title, body in
            Task { @MainActor in
                let _ = try? await container.noteRepository.upsert(Note(
                    id: UUID().uuidString,
                    title: title,
                    bodyHTML: body,
                    bodyPlaintext: body,
                    isPinned: false,
                    isDeleted: false,
                    createdAt: Date(),
                    updatedAt: Date(),
                    folderID: nil
                ))
                quickNotePanelController.hide()
                container.toastManager?.showSuccess("Note saved")
            }
        },
        onDismiss: {
            quickNotePanelController.hide()
        }
    )
    .environmentObject(container)
)
#endif
```

- [ ] **Step 4: Build and verify**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven && xcodegen generate && xcodebuild -project Haven.xcodeproj -scheme HavenMac -configuration Debug -destination "platform=macOS" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -15
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(mac): add Quick Note panel with global hotkey (Cmd+Shift+N)

- QuickNotePanel: floating NSPanel with title, body, save/discard
- GlobalHotkey: Carbon RegisterEventHotKey for system-wide capture
- Wired to menu bar and notification system"
```

---

## Task 7: Adapt HavenApp for macOS lifecycle and remaining platform guards

**Files:**
- Modify: `Haven/App/HavenApp.swift`
- Modify: `Haven/Views/Shared/HavenNavigationStack.swift`
- Modify: `Haven/Views/NoteEditor/NoteEditorView.swift` (any remaining iOS-only refs)

- [ ] **Step 1: Guard iOS-only App lifecycle code**

In `HavenApp.swift`, find and guard platform-specific code:

The `UIApplication` scene phase handling, `UIImpactFeedbackGenerator`, and any `UIKit`-specific imports:

```swift
#if os(iOS)
import UIKit
#endif
```

Guard the lock screen presentation (different on macOS):

```swift
// Lock screen
if isLocked {
    #if os(iOS)
    LockScreenView(...)  // Full-screen overlay
    #elseif os(macOS)
    // On macOS, lock is handled via sheet on the main window
    // Content is hidden until authenticated
    Color.havenBackground
        .sheet(isPresented: .constant(true)) {
            VStack(spacing: Spacing.xl) {
                Text("H")
                    .font(.system(size: 72, design: .serif))
                    .foregroundColor(Color.havenPrimary)
                Text("Haven is Locked")
                    .font(.havenHeadline)
                Button("Unlock") {
                    Task { await attemptUnlock() }
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .tint(Color.havenPrimary)
            }
            .frame(width: 300, height: 250)
            .interactiveDismissDisabled()
        }
    #endif
}
```

Guard `UIImpactFeedbackGenerator` calls throughout:

```swift
#if os(iOS)
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()
#endif
```

- [ ] **Step 2: Guard any remaining UIKit refs in views**

Search for remaining `UIKit` imports in shared view files:

```bash
grep -r "import UIKit" Haven/Views/ --include="*.swift"
```

For each hit, either:
- Replace with `#if os(iOS) import UIKit #endif` if the UIKit usage is guarded
- Or add `#if os(iOS)` around the UIKit-specific code

Common patterns to guard:
- `UIApplication.shared` → `#if os(iOS) UIApplication.shared.sendAction(...) #endif`
- `UIImpactFeedbackGenerator` → guard with `#if os(iOS)`
- `UIScreen.main` → not used on macOS

- [ ] **Step 3: Handle window management on macOS**

In `HavenNavigationStack.swift`, the `NavigationSplitView` already handles three-column for regular size class. Add macOS-specific toolbar styling:

```swift
#if os(macOS)
.toolbar {
    ToolbarItem(placement: .navigation) {
        Button {
            NSApp.keyWindow?.firstResponder?.tryToPerform(
                #selector(NSSplitViewController.toggleSidebar(_:)),
                with: nil
            )
        } label: {
            Image(systemName: "sidebar.left")
        }
    }
}
#endif
```

- [ ] **Step 4: Build both targets**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven && xcodegen generate

# Build iOS
xcodebuild -project Haven.xcodeproj -scheme Haven -configuration Debug -destination "generic/platform=iOS" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5

# Build macOS
xcodebuild -project Haven.xcodeproj -scheme HavenMac -configuration Debug -destination "platform=macOS" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: BOTH targets build successfully. No regressions on iOS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(mac): adapt app lifecycle, lock screen, and remaining platform guards

- macOS lock screen as sheet instead of full-screen overlay
- Guard UIKit imports and haptic feedback for iOS only
- Sidebar toggle toolbar button on macOS
- Both iOS and macOS targets build successfully"
```

---

## Task 8: Final verification and polish

**Files:**
- All modified files

- [ ] **Step 1: Full clean build — both targets**

```bash
cd /Users/youneshaddaj/Projects/notes-classic-ios/Haven && xcodegen generate

# Clean build iOS
xcodebuild -project Haven.xcodeproj -scheme Haven -configuration Debug -destination "generic/platform=iOS" clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5

# Clean build macOS
xcodebuild -project Haven.xcodeproj -scheme HavenMac -configuration Debug -destination "platform=macOS" clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

Expected: Both BUILD SUCCEEDED.

- [ ] **Step 2: Run existing unit tests on iOS**

```bash
xcodebuild test -project Haven.xcodeproj -scheme Haven -destination "platform=iOS Simulator,name=iPhone 16" 2>&1 | tail -20
```

Expected: All existing tests pass. No regressions.

- [ ] **Step 3: Verify macOS app launches**

```bash
# Build and run the macOS app
xcodebuild -project Haven.xcodeproj -scheme HavenMac -configuration Debug -destination "platform=macOS" build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5

# Find and launch the built app
open "$(xcodebuild -project Haven.xcodeproj -scheme HavenMac -configuration Debug -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | awk '{print $3}')/Haven.app"
```

Manual verification checklist:
- [ ] App launches and shows three-column layout
- [ ] Sidebar shows All Notes, Daily Note, Search, Graph, Folders, Tags
- [ ] Creating a new note (Cmd+N) works
- [ ] Typing in the editor shows live markdown highlighting
- [ ] Cmd+B/I toggles bold/italic in editor
- [ ] Cmd+, opens Settings with tabs
- [ ] Cmd+Shift+N opens Quick Note floating panel
- [ ] Window resizing works, columns resize properly
- [ ] Dark mode adapts correctly

- [ ] **Step 4: Commit final state**

```bash
git add -A
git commit -m "feat(mac): Haven for Mac — complete macOS target

Three-column native macOS app sharing 90%+ of iOS codebase.
- NSTextView editor with live markdown highlighting
- Full keyboard shortcuts (Cmd+B/I/K/H/N/F)
- Menu bar with File/Format/View commands
- Quick Note floating panel (Cmd+Shift+N)
- macOS Settings scene with tabs
- Touch ID lock screen support
- Universal purchase via same bundle ID"
```
