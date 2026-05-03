# Roadmap — Automation & Daily Wallpaper Loop

Ideas captured 2026-05-03 after v1.0.1 (vertical offset + inline preview button).
Ship target: post-v1.0.1 release on App Store.

## Audit findings

- **Shortcuts integration is REAL, not stub.** 3 AppIntents in
  `LockScreenStudio/Sources/Intents/WallpaperIntents.swift` (`GenerateTodayWallpaperIntent`,
  `GenerateWallpaperIntent`, `GenerateWallpaperWithParametersIntent`). All have
  `openAppWhenRun = false`, registered via `AppShortcutsProvider`, return real
  `IntentFile` PNGs. Only friction: Apple forces 6-step manual setup in Shortcuts.app.
- **No WidgetKit target exists.** `project.yml` has only the app + tests targets.
- **BackgroundTaskManager exists** with timer-based refresh (6/12/24/48h) but is
  NOT event-driven — marking a todo done does not trigger refresh.
- **Panel config is JSON-snapshot in UserDefaults** (`BackgroundTaskManager:108-160`),
  not in SwiftData. Hidden from user, hard to share with widget extensions.
- **TodoItem has no `completedAt` timestamp** — cannot build daily/weekly history.

## Top 3 UX frictions identified

1. **Toggling a todo done is a 5-step round trip**: Editor → todo checkbox →
   Generate button → Photos app → set wallpaper. Should be 1-2 taps.
2. **Panel config invisible to user** — saved silently to UserDefaults; if user
   edits template, background refresh may use stale snapshot until they toggle
   auto-refresh in Settings.
3. **Onboarding TabView is ambiguous** — `.page` style allows swipe AND has a
   "Get Started" button; users unsure which is intended (`OnboardingView.swift:12-20`).

## Three-tier plan

### Tier 1 — Event-driven refresh (1-2 days, ~50 LOC)

When user toggles `todo.isCompleted` in EditorView:
- Call `BackgroundTaskManager.savePanelsForRefresh(template.panels)` to refresh
  the UserDefaults snapshot
- If `autoRefreshEnabled`, regenerate immediately (don't wait for next BGTask)
- Push notification "Wallpaper updated — tap to set" with deep link to Photos

Files: `EditorView.swift:244-298` (todo toggle), `BackgroundTaskManager.swift`
(expose synchronous trigger). No new targets, no entitlements, no schema change.

**Why first:** highest-impact-per-line-of-code change in the whole roadmap.

### Tier 2 — Daily wallpaper history / "productivity journal" (3-5 days)

The big retention play. Turns the app from "wallpaper editor" to "visual journal".

- SwiftData migration: add `completedAt: Date?` on `TodoItem`
- New tab/section: GitHub-style heatmap of completed todos per day
  (the habits-heatmap idea pulled from v1.0 — see memory entry)
- Nightly `BGProcessingTask`: at midnight, render and archive yesterday's
  wallpaper into `ExportHistoryItem` (model already exists)
- "Throwback" view: scroll back through past wallpapers as a memory artifact

No widget required. No App Groups. Pure in-app value.

### Tier 3 — Widget with "mark done" + auto-regenerate (1-2 weeks)

The killer feature, but technically the heaviest:

- New WidgetKit extension target in `project.yml`
- App Groups entitlement (currently absent in `LockScreenStudio.entitlements`)
- Migrate panel config + todos to shared App Group container
  (SwiftData does NOT work cleanly across app/widget process boundary —
  use Codable JSON in shared `UserDefaults(suiteName:)` or migrate to Core Data)
- `AppIntent` with `.perform` action on widget button:
  - mark todo done in shared store
  - call `ExportService.generateWallpaper()` headless
  - save PNG to App Group container
  - `WidgetCenter.shared.reloadTimelines(ofKind:)`

Risks: widget memory limits on iOS 18 are tight; rendering full wallpaper inside
extension may need a downscaled path.

## Open questions to resolve before implementation

1. Daily-wallpaper feature: heatmap view shown in-app, or invisible engine that
   only feeds the wallpaper? They're different products.
2. Widget priority: must-have for v1.1, or defer to v1.2 and ship Tiers 1+2 first?
   (Recommended: defer — Tiers 1+2 are far cheaper for similar perceived value.)
3. Onboarding fix: in-scope alongside Tier 1, or separate polish pass?

## Pre-existing related docs

- [SHORTCUTS_DESIGN.md](SHORTCUTS_DESIGN.md) — original shortcuts intent design
- [EXTRA_IDEAS.md](EXTRA_IDEAS.md) — Focus Mode sync, Morning Briefing chain,
  other automation marketing ideas
