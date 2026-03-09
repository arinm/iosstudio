# Lock Screen Studio — Architecture Overview

## High-Level Architecture

```
┌─────────────────────────────────────────────────┐
│                   SwiftUI Layer                  │
│  Onboarding │ Gallery │ Editor │ Preview │ Export│
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────┐
│                  Service Layer                   │
│  ExportService │ CalendarService │ Subscription  │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────┐
│               Rendering Engine                   │
│  PanelDataBuilder → WallpaperRenderer            │
│  (UIGraphicsImageRenderer, deterministic output) │
└──────────────────────┬──────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────┐
│                 Data Layer                        │
│  SwiftData (DashboardProject, Template, Panels)  │
│  EventKit (Calendar Events)                      │
│  StoreKit 2 (Subscription State)                 │
│  UserDefaults (Settings, Export Counts)           │
└─────────────────────────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────┐
│               App Intents Layer                  │
│  GenerateTodayWallpaper                          │
│  GenerateWallpaper                               │
│  GenerateWallpaperWithParameters                 │
│  (Reuses ExportService + Renderer)               │
└─────────────────────────────────────────────────┘
```

## Key Design Decisions

### 1. UIGraphicsImageRenderer over SwiftUI ImageRenderer

**Why:** SwiftUI's `ImageRenderer` (iOS 16+) has known issues with:
- Inconsistent rendering across device types
- Text rendering differences
- Layout ambiguity with certain view hierarchies

`UIGraphicsImageRenderer` provides:
- Deterministic pixel output
- Full control over drawing operations
- Better performance for repeated rendering
- Reliable text layout with NSAttributedString

**Trade-off:** More verbose drawing code, but much more reliable output.

### 2. SwiftData over CoreData

**Why:** SwiftData is the right choice for this project because:
- Simpler model definition (no `.xcdatamodeld` file)
- Native Swift types, Codable enums, better ergonomics
- Automatic CloudKit sync capability if needed later
- iOS 17+ target aligns with SwiftData availability

**Risk:** SwiftData is newer and has fewer escape hatches. Mitigated by keeping the data model simple and using JSON-encoded config blobs for panel-specific settings.

### 3. Panel Config as JSON Blobs

Each panel type has different configuration needs (AgendaConfig, TopThreeConfig, etc.). Rather than creating separate SwiftData models for each panel type's config, we store config as `Data` (JSON) on `PanelConfiguration` and decode with type-specific Codable structs.

**Why:**
- Avoids model explosion (no need for AgendaPanelConfig, TodoPanelConfig, etc.)
- Easy to add new panel types without schema migration
- Config structs are simple value types, easy to test

### 4. Actor-based CalendarService

`CalendarService` is an `actor` to safely handle EventKit access from multiple contexts (main app + App Intents). EventKit is thread-safe for reads, but actor isolation prevents any potential race conditions.

### 5. Render Theme as Value Type

`RenderTheme` is a struct (not a SwiftData model) because:
- It's a computed value derived from `ThemeConfiguration`
- It's used transiently during rendering
- No need to persist render-specific values (font sizes in pixels, etc.)

### 6. Export Counter in UserDefaults

Free tier export limits are tracked in UserDefaults (not SwiftData) because:
- Simple date+count pair, no need for relational model
- Reset daily based on date string comparison
- Fast to read/write during export flow

---

## iOS Version Justification

**Target: iOS 17+**

| Feature | iOS Version | Justification |
|---------|-------------|---------------|
| SwiftData | iOS 17+ | Primary persistence framework |
| SwiftUI improvements | iOS 17+ | NavigationStack stability, Observable macro |
| App Intents enhancements | iOS 17+ | Better parameter types, ShortcutsProvider |
| EventKit full access | iOS 17+ | `requestFullAccessToEvents()` API |
| StoreKit 2 maturity | iOS 15+ (stable by 17) | Transaction.currentEntitlements reliability |

iOS 18 adds interactive widgets and more advanced intent features, but nothing essential for the MVP. We target iOS 17+ for maximum reach while using modern APIs.

---

## File Structure

```
LockScreenStudio/
├── Sources/
│   ├── App/
│   │   ├── LockScreenStudioApp.swift     # Entry point, ModelContainer
│   │   └── MainTabView.swift             # Root navigation
│   ├── Models/
│   │   ├── DashboardProject.swift        # Root project model
│   │   ├── WallpaperTemplate.swift       # Template + LayoutType
│   │   ├── PanelConfiguration.swift      # Panel model + all config structs
│   │   ├── ThemeConfiguration.swift      # Theme model + color/font enums
│   │   ├── ExportPreset.swift            # Export sizes + DevicePreset
│   │   └── TodoItem.swift                # Todo + Priority persistence
│   ├── Renderer/
│   │   ├── WallpaperRenderer.swift       # Core rendering engine
│   │   └── PanelDataBuilder.swift        # Model → render data bridge
│   ├── Services/
│   │   ├── CalendarService.swift         # EventKit wrapper
│   │   ├── SubscriptionManager.swift     # StoreKit 2 manager
│   │   ├── ExportService.swift           # Generation + export pipeline
│   │   └── TemplateSeeder.swift          # First-launch template seeding
│   ├── Intents/
│   │   └── WallpaperIntents.swift        # All App Intents + ShortcutsProvider
│   └── Views/
│       ├── Onboarding/
│       │   └── OnboardingView.swift
│       ├── Gallery/
│       │   └── TemplateGalleryView.swift
│       ├── Editor/
│       │   └── EditorView.swift          # + PanelConfigSheet
│       ├── Preview/
│       │   └── PreviewView.swift
│       ├── Export/
│       │   └── ExportView.swift
│       ├── Paywall/
│       │   └── PaywallView.swift
│       ├── Settings/
│       │   ├── SettingsView.swift
│       │   └── ShortcutsGuideView.swift
│       └── Components/
│           └── ThemePickerSheet.swift
├── Resources/
│   └── Assets.xcassets/
├── Tests/
│   └── (unit tests)
└── docs/
    ├── SPEC.md
    ├── UI_WIREFRAMES.md
    ├── SHORTCUTS_DESIGN.md
    └── ARCHITECTURE.md
```

---

## Device Resolution & Safe Area Handling

### Strategy

1. **Static device database:** `DevicePreset.allPresets` contains all supported iPhone resolutions and safe area insets.
2. **Auto-detection:** `DevicePreset.current` matches the running device's `UIScreen.main.nativeBounds` to the nearest preset.
3. **Manual override:** Users (and Shortcuts) can specify a target device.
4. **Safe area insets:** Each preset defines top (clock/DI), bottom (home indicator), and side insets in native pixels.
5. **Render-time application:** The renderer subtracts safe areas from the content rect before drawing panels.

### Safe Area Sources

Safe area values are measured in native pixels (not points) from device specifications:

| Device | Resolution | Top Safe (clock/DI) | Bottom Safe | Has DI |
|--------|-----------|---------------------|-------------|--------|
| iPhone 16 Pro Max | 1320×2868 | 330px | 102px | Yes |
| iPhone 16 Pro | 1206×2622 | 310px | 96px | Yes |
| iPhone 15 Pro | 1179×2556 | 300px | 93px | Yes |
| iPhone 15 Pro Max | 1290×2796 | 320px | 99px | Yes |
| iPhone 14 | 1170×2532 | 282px | 93px | No |
| iPhone SE | 750×1334 | 180px | 0px | No |

### Updating for New Devices

When Apple releases new iPhone models, update `DevicePreset.allPresets` with:
1. New native resolution
2. Measured safe area insets
3. Dynamic Island flag

This is a data-only change — no code modification needed.

---

## Caching Strategy

| Data | Cache Location | TTL | Invalidation |
|------|---------------|-----|-------------|
| Calendar events | In-memory (CalendarService) | Per-request | N/A (fetched fresh each generation) |
| Rendered preview | @State in PreviewView | Session | View re-creation |
| Template data | SwiftData (disk) | Permanent | User edits |
| Subscription state | In-memory (SubscriptionManager) | Session | Transaction.updates listener |
| Export count | UserDefaults | 1 day | Date comparison |

No aggressive caching is needed because:
- Generation is fast (<500ms)
- Data sources are local (no network latency)
- Fresh data is more important than cache hits for a daily wallpaper
