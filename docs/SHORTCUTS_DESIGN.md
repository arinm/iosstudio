# Lock Screen Studio — Shortcuts / App Intents Design

## Overview

Lock Screen Studio exposes App Intents (iOS 16+ / App Intents framework) that integrate with Apple Shortcuts. This enables users to automate daily wallpaper generation without opening the app.

**Key constraint:** iOS does not have a public API to set wallpaper programmatically from within an app. The wallpaper-setting step must happen via the Shortcuts "Set Wallpaper" action (available iOS 16.4+). Our intents generate and return an image; the user chains it with "Set Wallpaper" in their Shortcut.

---

## Intent Definitions

### Intent 1: Generate Today Wallpaper (Free)

| Property | Value |
|----------|-------|
| Name | `GenerateTodayWallpaperIntent` |
| Title | "Generate Today Wallpaper" |
| Description | Creates a wallpaper using the default template with today's date |
| Parameters | None |
| Returns | `IntentFile` (PNG image) |
| Opens App | No |
| Tier | Free |

**Behavior:**
1. Fetches the first non-Pro template (or user's default template).
2. Fetches today's calendar events via EventKit.
3. Fetches current priorities and to-dos from SwiftData.
4. Renders wallpaper at the current device's resolution.
5. Saves to temp file, returns as IntentFile.

**Siri Phrases:**
- "Generate today's wallpaper with Lock Screen Studio"
- "Create today's lock screen with Lock Screen Studio"
- "Make my daily wallpaper with Lock Screen Studio"

---

### Intent 2: Generate Wallpaper (Pro)

| Property | Value |
|----------|-------|
| Name | `GenerateWallpaperIntent` |
| Title | "Generate Wallpaper" |
| Description | Creates a wallpaper using a chosen template and theme |
| Parameters | `templateName` (enum), `theme` (dark/light) |
| Returns | `IntentFile` (PNG image) |
| Opens App | No |
| Tier | Pro |

**Parameters:**
- `templateName`: Enum of all built-in templates (Today Dashboard, Minimal Agenda, etc.)
- `theme`: Dark or Light

---

### Intent 3: Generate Wallpaper — Advanced (Pro)

| Property | Value |
|----------|-------|
| Name | `GenerateWallpaperWithParametersIntent` |
| Title | "Generate Wallpaper (Advanced)" |
| Description | Full parameter control for power users |
| Parameters | `templateName`, `date`, `theme`, `device`, `format` |
| Returns | `IntentFile` (PNG/JPEG image) |
| Opens App | No |
| Tier | Pro |

**Parameters:**
- `templateName`: Enum of all templates
- `date`: Optional Date (defaults to today)
- `theme`: Dark or Light
- `device`: Auto-detect, or specific iPhone model
- `format`: PNG or JPEG

**Power User Use Cases:**
- Generate tomorrow's wallpaper the night before
- Generate a specific device's wallpaper (e.g., for a secondary phone)
- Generate JPEG for smaller file size in automations

---

## Output Flow

```
Shortcut Automation (6:00 AM daily)
  │
  ├─ Action 1: "Generate Today Wallpaper"
  │     → Returns: wallpaper.png (IntentFile)
  │
  ├─ Action 2: "Set Wallpaper" (Apple built-in)
  │     → Input: wallpaper.png from Action 1
  │     → Screen: Lock Screen
  │     → Perspective: Off
  │
  └─ Done (no notification needed)
```

**Important:** The "Set Wallpaper" action is provided by iOS, not by our app.
On iOS 16.4+, Shortcuts can set wallpaper without user confirmation if the
automation is set to "Run Immediately."

---

## Shortcut Pack Plan

### Shipped Shortcuts (installable from within the app)

| # | Shortcut Name | Actions | Tier |
|---|--------------|---------|------|
| 1 | "Daily Dashboard" | Generate Today Wallpaper → Set Wallpaper (Lock Screen) | Free |
| 2 | "Morning Briefing" | Generate Wallpaper (Today Dashboard, Dark) → Set Wallpaper | Pro |
| 3 | "Work Mode" | Generate Wallpaper (Minimal Agenda, Light) → Set Wallpaper (Lock+Home) | Pro |
| 4 | "Evening Reset" | Generate Wallpaper (Priority Focus, Dark) → Set Wallpaper | Pro |
| 5 | "Weekly Prep" | Generate Wallpaper (Advanced, next Monday's date) → Save to Photos | Pro |

### Installation Method

1. **In-app guide** (Settings → Shortcuts → Install Shortcuts): tapping each shortcut opens Shortcuts app with a pre-configured shortcut via URL scheme or iCloud shared link.
2. **iCloud links**: Host shortcuts on iCloud for easy sharing. Link format: `https://www.icloud.com/shortcuts/[id]`
3. **QR codes** (optional): For sharing in social media / blog posts.

### Onboarding Automation Setup

After first export, show a prompt:
> "Want this automatically every morning? Set up a daily Shortcut in 30 seconds."
> [Set Up Daily Shortcut] [Maybe Later]

The "Set Up" button opens the Shortcuts Guide screen with step-by-step instructions.

---

## Technical Notes

### Shared Data Access

App Intents run in the app's process (not an extension), so they have full access to:
- SwiftData ModelContainer (same store as the app)
- EventKit (if permission was previously granted)
- UserDefaults (for settings)

### Performance

- Target: < 500ms generation time for a single wallpaper.
- The renderer uses UIGraphicsImageRenderer which is hardware-accelerated.
- Calendar event fetching is cached for the day.
- No network calls needed — fully offline.

### Error Handling

| Scenario | Behavior |
|----------|----------|
| No templates found | Throw `IntentError.noTemplateFound` with helpful message |
| Calendar access denied | Render wallpaper without agenda panel (graceful degradation) |
| Pro template requested without subscription | Throw `IntentError.proRequired` |
| Render failure | Throw `IntentError.generationFailed` |

### Testing Intents

1. Build and run on device.
2. Open Shortcuts app → Create new shortcut.
3. Search "Lock Screen Studio" → see available actions.
4. Test each intent with different parameters.
5. Verify output file is valid PNG/JPEG at expected resolution.
6. Chain with "Set Wallpaper" to verify end-to-end flow.
