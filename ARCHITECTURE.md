# Haven — Architecture Plan

**Date**: March 26, 2026
**Stack**: Swift/SwiftUI, SQLite (GRDB), Infomaniak Rich HTML Editor, StoreKit 2
**Pattern**: MVVM with service layer
**Min iOS**: 16

## Build Order

| Batch | Files | Parallelism | Est. Time |
|-------|-------|-------------|-----------|
| 1 | Models, Extensions, Utilities (14 files) | Fully parallel | 1-2 hrs |
| 2 | Protocols (4 files) | Fully parallel | 30 min |
| 3 | Database + Editor + Subscription services (8 files) | Partially parallel | 3-4 hrs |
| 4 | Sync layer (4 files) | 3 parallel + 1 sequential | 2-3 hrs |
| 5 | App infrastructure (2 files) | Sequential | 30 min |
| 6 | ViewModels (6 files) | Fully parallel | 2-3 hrs |
| 7 | Views (15 files) | Fully parallel | 3-4 hrs |
| 8 | Entry point + previews (2 files) | Sequential | 30 min |
| 9 | Tests (9 files) | Fully parallel | 2-3 hrs |

## Dependency Layers

```
Layer 0: Models, Extensions, Utilities (no dependencies)
Layer 1: Protocols (depend on Models)
Layer 2: Services (depend on Protocols + Models)
Layer 3: App Infrastructure (depend on Services)
Layer 4: ViewModels (depend on Protocols via DI)
Layer 5: Views (depend on ViewModels + Extensions)
```

## SQLite Library: GRDB

Using GRDB Swift package for:
- Swift-native API
- WAL mode support
- Built-in FTS5 support
- Thread-safe database access

## Navigation

Path-based NavigationStack with Route enum:
```
NoteList → NoteEditor → WikiLink target
NoteList → Search → NoteEditor
NoteList → Settings → Sync / Subscription
```
