# Haven Quick Capture Widget — Setup Guide

## Overview

The Quick Capture widget lets users create a new note instantly from the home screen or lock screen. Tapping the widget opens Haven directly into the note editor via the `haven://` URL scheme.

## Architecture

```
Haven (main app)
├── App/DeepLinkHandler.swift   — Parses haven:// URLs
├── App/AppState.swift          — PendingAction enum added
├── App/HavenApp.swift          — .onOpenURL handler added
└── Info.plist                  — haven:// URL scheme registered

HavenWidgetExtension (widget target)
└── HavenWidget/HavenWidget.swift — Widget views + provider
```

## Deep Link Scheme

| URL | Action |
|-----|--------|
| `haven://new-note` | Opens editor with a blank note |
| `haven://daily-note` | Opens (or creates) today's daily note |

## Widget Families

| Family | Description |
|--------|-------------|
| `systemSmall` | Single tap — opens new note |
| `systemMedium` | Two buttons — New Note + Daily Note |
| `accessoryCircular` | Lock screen icon — tap for new note |
| `accessoryRectangular` | Lock screen label — tap for new note |

## Setup with XcodeGen

The widget target is already defined in `project.yml` as `HavenWidgetExtension`. After editing, regenerate the Xcode project:

```bash
xcodegen generate
```

Then open `Haven.xcodeproj` — the widget target and its embedding dependency will be configured automatically.

## Manual Setup (if not using XcodeGen)

If you need to add the widget target manually in Xcode:

1. **File > New > Target > Widget Extension**
2. Name it `HavenWidgetExtension`
3. Bundle ID: `com.haven.app.widget`
4. Uncheck "Include Configuration App Intent" (we use `StaticConfiguration`)
5. Delete the generated Swift files and use `HavenWidget/HavenWidget.swift` instead
6. Ensure the widget extension is embedded in the Haven app target (Build Phases > Embed App Extensions)

## Testing

1. Build and run the Haven scheme on a simulator or device
2. Long-press the home screen > tap **+** (top left)
3. Search for "Haven" in the widget gallery
4. Add the Small or Medium widget
5. Tap the widget — Haven should open into the note editor

For lock screen widgets (iOS 16+):
1. Long-press the lock screen > Customize
2. Tap the widget area below the clock
3. Add Haven's circular or rectangular widget

## Future Enhancements

- Show recent note titles in a large widget
- Share note count via App Groups + UserDefaults
- Add an App Intent for interactive note creation directly from the widget (iOS 17+)
