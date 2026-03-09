# Lock Screen Studio — Product Spec & Engineering Plan

## 1. Product Vision

**One-liner:** Lock Screen Studio turns your iPhone Lock Screen into a live productivity dashboard — agenda, to-dos, habits, and priorities rendered as a beautiful wallpaper, refreshed daily via Shortcuts.

**North Star Experience:**
Install → Pick "Today Dashboard" template → Grant calendar access → See today's agenda rendered on your Lock Screen → Export → Set as wallpaper → Enable daily Shortcut → Never think about it again.

Time to "aha": **< 60 seconds.**

---

## 2. Target User Personas

| Persona | Description | Key Need | Willingness to Pay |
|---------|-------------|----------|-------------------|
| **Shortcut Power User** | Runs 10+ automations, active on r/shortcuts, wants predictable outputs | Full App Intents, parameterized generation, zero friction | High — pays for tools that integrate well |
| **Productivity Minimalist** | GTD/bullet journal user, wants glanceable daily overview | Clean design, top-3 priorities, agenda at a glance | Medium — pays for aesthetics + utility |
| **Aesthetic Customizer** | Curates Home/Lock Screen regularly, uses Widgetsmith-style apps | Templates, themes, typography options, dark/light modes | High — pays for premium themes |
| **Casual User** | Saw it on TikTok/Twitter, wants a cool Lock Screen | One-tap template, instant preview, no setup complexity | Low — free tier, converts if hooked |

---

## 3. Primary Use Cases

1. **Daily Dashboard Wallpaper** — Morning automation generates wallpaper with today's calendar, top 3 priorities, and habit streak.
2. **Work/Gym/Travel Modes** — Switch wallpaper context: "Work" shows meetings + deadlines, "Gym" shows workout plan, "Travel" shows itinerary.
3. **Manual Refresh** — Open app, tweak priorities, regenerate wallpaper on demand.
4. **Shortcut-Driven Automation** — Shortcuts triggers at 6 AM: generate wallpaper → set as Lock Screen (via Shortcuts' native wallpaper action on iOS 16+).
5. **Weekly Planning** — Sunday evening: set up the week's priorities, generate wallpapers for each day.

---

## 4. Feature List: MVP vs vNext

### MVP (v1.0) — P0

| Feature | Description |
|---------|-------------|
| Template Gallery | 4-6 pre-built templates (Today Dashboard, Minimal Agenda, Priorities Only, Weekly Overview, Dark Focus, Split Layout) |
| Panel System | Agenda Panel, To-Do Panel (manual entry), Today Top 3 Panel, Date/Time Panel |
| Editor Screen | Reorder panels, toggle visibility, quick-edit text content |
| Live Preview | Real-time wallpaper preview with device frame overlay |
| Safe Area Overlay | Toggle showing clock/Dynamic Island/widget exclusion zones |
| Export | Generate PNG at device resolution, share sheet, save to Photos |
| Device Presets | iPhone 14/15/16 Pro, Pro Max, standard sizes |
| Theme System | Light, Dark, Auto (follows system); 4 color accent presets |
| App Intents (3) | GenerateWallpaper, GenerateTodayWallpaper, GenerateWithParameters |
| Calendar Integration | EventKit: read today's/week's events, display in Agenda panel |
| Subscription (StoreKit 2) | Free tier + Pro (monthly/yearly), paywall, restore |
| Onboarding | 3-screen flow: value prop → permissions → first template |
| Settings | Theme, default template, manage subscription, about |
| Offline-First | Everything works without network |

### vNext (v1.1+) — P1/P2

| Priority | Feature |
|----------|---------|
| P1 | Habits Heatmap panel (GitHub-style grid) |
| P1 | Reminders integration (EventKit Reminders) |
| P1 | Custom templates (user creates layouts) |
| P1 | Shortcut Pack: pre-built shortcuts with install flow |
| P1 | More typography options (font families, weights) |
| P2 | Weather panel (WeatherKit) |
| P2 | Widget companion (iOS 17 interactive widgets) |
| P2 | Template sharing (export/import template JSON) |
| P2 | Smart Switching (time-based mode auto-switch via Shortcuts) |
| P2 | Photo background support (blur + overlay panels) |
| P2 | Multiple wallpaper queue (pre-generate week's wallpapers) |

---

## 5. Free vs Pro Feature Gating

| Capability | Free | Pro |
|-----------|------|-----|
| Templates | 2 (Today Dashboard, Minimal Agenda) | All templates (6+ and growing) |
| Panels per template | Up to 3 | Unlimited |
| Exports per day | 3 | Unlimited |
| Themes | Light + Dark | + 6 premium color themes |
| Typography | System font only | 4 font families, weight control |
| Device presets | Auto-detect only | All presets + custom resolution |
| App Intents | GenerateTodayWallpaper only | All 3 intents, full parameters |
| Safe area overlay | Yes | Yes |
| Shortcut Pack | Basic (1 shortcut) | Full pack (5+ shortcuts) |
| Priority support | — | Yes |

### Pricing

| Plan | Price | Rationale |
|------|-------|-----------|
| Monthly | €2.99 / $2.99 | Low friction trial; comparable to Widgetsmith Pro |
| Yearly | €19.99 / $19.99 | ~44% discount; strong conversion driver |
| Lifetime (optional P2) | €49.99 | For power users who hate subscriptions |

### Paywall Strategy

- **Trigger:** After first successful export (user has seen value).
- **Soft paywall:** "You've created your first wallpaper! Unlock unlimited templates and daily automation with Pro." Show preview of Pro templates behind blur.
- **No hard gate on core flow.** Free users can always generate and export basic wallpapers.
- **Trial:** 3-day free trial for yearly plan.

---

## 6. Navigation Map

```
App Launch
  │
  ├─ [First Launch] → Onboarding (3 screens)
  │                      → Template Gallery
  │
  ├─ Template Gallery (Home)
  │     ├─ Template Card tap → Editor
  │     ├─ Settings gear → Settings
  │     └─ "New" (Pro) → Template Builder (vNext)
  │
  ├─ Editor
  │     ├─ Panel list (reorder, toggle, edit)
  │     ├─ Theme picker (bottom sheet)
  │     ├─ "Preview" → Preview Screen
  │     └─ "Generate" → Export Screen
  │
  ├─ Preview Screen
  │     ├─ Device frame + wallpaper
  │     ├─ Safe area overlay toggle
  │     ├─ "Export" → Export Screen
  │     └─ Back → Editor
  │
  ├─ Export Screen
  │     ├─ Resolution picker
  │     ├─ Format (PNG/JPEG)
  │     ├─ "Save to Photos" / "Share"
  │     └─ [Free limit reached] → Paywall
  │
  ├─ Paywall
  │     ├─ Plan selection
  │     ├─ "Subscribe" / "Restore"
  │     └─ Dismiss → back
  │
  └─ Settings
        ├─ Theme (system/light/dark)
        ├─ Default template
        ├─ Subscription management
        ├─ Calendar permissions
        ├─ Shortcuts guide
        ├─ About / Privacy
        └─ Reset
```

---

## 7. Risk Register

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| iOS has no public API to set wallpaper programmatically | High | Confirmed limitation | Use Shortcuts' "Set Wallpaper" action (iOS 16+); provide clear user guidance |
| Calendar permission denied | Medium | Medium | Graceful fallback: show manual-entry panels, prompt re-ask later |
| SwiftUI ImageRenderer inconsistencies across devices | Medium | Medium | Use UIGraphicsImageRenderer as primary; SwiftUI ImageRenderer as fallback |
| Safe area dimensions change with new iPhone models | Low | High (yearly) | Data-driven safe area map; easy to update per device |
| StoreKit 2 edge cases (family sharing, refunds) | Low | Medium | Follow Apple's recommended patterns; test with sandbox |
| Shortcuts automation reliability | Medium | Medium | Expose simple, focused intents; extensive testing; user documentation |
| Large calendar data slowing render | Low | Low | Limit to 10 events per panel; paginate if needed |

---

## 8. Testing Strategy

| Layer | Tool | What |
|-------|------|------|
| Unit Tests | XCTest | Renderer output dimensions, panel layout logic, theme color calculations, date formatting, safe area calculations |
| Snapshot Tests | swift-snapshot-testing | Rendered wallpaper images for regression (compare pixel output across OS versions) |
| Integration Tests | XCTest | EventKit data → Panel model → Rendered image pipeline |
| UI Tests | XCUITest | Onboarding flow, export flow, paywall flow |
| Intent Tests | XCTest | App Intent parameter validation, output format, error handling |
| Manual QA | TestFlight | Device matrix: iPhone 14, 15 Pro, 16 Pro Max; iOS 17, 18 |

---

## 9. Backlog (Prioritized)

| ID | Priority | Task | Acceptance Criteria |
|----|----------|------|-------------------|
| 1 | P0 | SwiftData models + persistence | All models compile, CRUD works, migration path defined |
| 2 | P0 | Panel protocol + 4 panel implementations | Each panel renders correctly in isolation |
| 3 | P0 | Wallpaper renderer (UIGraphicsImageRenderer) | Produces correct-resolution PNG, deterministic output |
| 4 | P0 | Template Gallery screen | Shows 4+ templates with preview thumbnails |
| 5 | P0 | Editor screen | Panels list, reorder, toggle, inline edit |
| 6 | P0 | Preview screen with safe area overlay | Accurate overlay for iPhone 14/15/16 Pro |
| 7 | P0 | Export flow (save to Photos, share sheet) | Correct resolution, format selection works |
| 8 | P0 | Calendar integration (EventKit) | Permission flow, fetch events, display in panel |
| 9 | P0 | Theme system (light/dark + 4 accents) | All panels respect theme, system auto works |
| 10 | P0 | Onboarding (3 screens) | Completes in <30s, permissions requested correctly |
| 11 | P0 | App Intents (3 intents) | All intents work in Shortcuts, return correct output |
| 12 | P0 | StoreKit 2 subscription | Purchase, restore, receipt validation, feature gating |
| 13 | P0 | Paywall screen | Shows after first export, plan selection, purchase flow |
| 14 | P0 | Settings screen | All settings functional, subscription management |
| 15 | P1 | Device preset system | Resolution database, auto-detect, manual override |
| 16 | P1 | Shortcut Pack (pre-built shortcuts) | 3+ shortcuts, install guide, tested end-to-end |
| 17 | P1 | Habits Heatmap panel | GitHub-style grid, manual data entry |
| 18 | P1 | Reminders integration | Permission flow, fetch reminders, display in panel |
| 19 | P1 | Custom template builder | Drag-drop panels, save custom layout |
| 20 | P2 | Weather panel | WeatherKit integration, location permission |
| 21 | P2 | Photo background | Photo picker, blur, overlay composition |
| 22 | P2 | Template sharing | Export/import JSON, share sheet |
