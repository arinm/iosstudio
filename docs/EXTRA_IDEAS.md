# Lock Screen Studio — 5 Extra Ideas

## 1. "Focus Mode Wallpaper Sync" (Shortcuts-powered)

**Concept:** Automatically switch wallpaper when iOS Focus Mode changes.

**How it works:**
- User creates a Shortcut automation triggered by Focus Mode activation (Work, Personal, Fitness, etc.)
- Each Focus Mode maps to a different template: "Work" → Minimal Agenda, "Fitness" → Priority Focus (with workout goals), "Personal" → dark minimal
- The automation calls "Generate Wallpaper" with the appropriate template → "Set Wallpaper"

**Why it's unique to Lock Screen Studio:**
- No other wallpaper app exposes parameterized Shortcuts intents that let you pick a template per-context
- Creates a truly contextual phone experience: your Lock Screen matches your current mode

**Implementation:** Already supported by the existing `GenerateWallpaperIntent` with template parameter. Marketing opportunity: create a "Focus Mode Pack" with 3-4 pre-built automations.

---

## 2. "Shortcut Chain: Morning Briefing Pipeline"

**Concept:** A multi-step Shortcut that gathers data from multiple sources before generating a wallpaper.

**Example Shortcut flow:**
1. Get weather forecast (Weather action)
2. Get first 3 calendar events (Calendar action)
3. Get a motivational quote from a text file or Shortcuts input
4. Set Shortcuts variables for priority 1, 2, 3
5. Call "Generate Wallpaper (Advanced)" with parameters
6. Set as Lock Screen wallpaper
7. Optionally: also generate a Home Screen variant

**Why it's unique:**
- Leverages Shortcuts as a "data pipeline" that feeds into Lock Screen Studio
- Power users can create incredibly personalized morning routines
- The app doesn't need to integrate weather/quotes/etc. natively — Shortcuts handles the data gathering, our app handles the rendering

**Implementation:** Add an optional "subtitle" or "extra text" parameter to the Advanced intent that power users can inject with data from earlier Shortcut steps. This single parameter unlocks infinite composability.

---

## 3. "Wallpaper History & Stats"

**Concept:** Save every generated wallpaper with metadata, creating a visual diary of your days.

**Features:**
- History gallery: scroll through past wallpapers by date
- Stats: "Generated 47 wallpapers this month", "You've had 12 meetings this week"
- Trends: "Your most common Priority #1 this month: 'Review PRs'"
- Exportable: share a week/month montage as a single image

**Why it's unique to Lock Screen Studio:**
- The wallpaper _is_ the data visualization — saving wallpapers is literally saving daily snapshots of your productivity
- Nobody else offers "wallpaper archaeology" — look back at what your priorities were 3 months ago
- The stats come for free from the data we already have (calendar events, priorities, todos)

**Implementation (P2):**
- Store `WallpaperHistory` model: date, template name, thumbnail data, priority texts
- Lightweight: only save metadata + compressed thumbnail (not full-res image)
- History view with month calendar grid (tap a day → see that day's wallpaper)

---

## 4. "Collaborative Priority Board" (via Shared Shortcuts)

**Concept:** Share a Shortcut that lets a partner/team set your phone's priority list.

**How it works:**
1. User A creates a Shortcut with "Ask for Input" → "Set priority via Lock Screen Studio"
2. User A shares this Shortcut with User B (partner, assistant, manager)
3. User B runs the Shortcut → types 3 priorities → Lock Screen Studio generates the wallpaper on User A's phone

**Why it's unique:**
- Uses Shortcuts' sharing + input capabilities to create a collaborative feature without any server infrastructure
- Couples: one partner sets the other's daily priorities as a sweet gesture
- Assistants: an EA can set the executive's Lock Screen priorities remotely

**Implementation:** Add an App Intent that accepts priority text parameters directly: `SetPrioritiesIntent(priority1: String, priority2: String, priority3: String)`. Then the shared Shortcut calls Set Priorities → Generate Wallpaper → Set Wallpaper.

---

## 5. "Themed Countdown Wallpapers"

**Concept:** A special panel/template that counts down to an important date, with the wallpaper changing daily.

**Examples:**
- "Launch day in 14 days" → "Launch day in 13 days" → ... → "LAUNCH DAY"
- Vacation countdown with changing background tones (cooler colors as you get closer)
- Birthday/anniversary countdown

**How it works:**
- New "Countdown" panel type: user sets target date and label
- Each day, the number changes automatically (via Shortcut automation)
- Optional: visual intensity increases as the date approaches (accent color gets more vivid, text gets bolder)

**Why it's unique to Lock Screen Studio:**
- The Lock Screen is the perfect place for a countdown — you see it 100+ times/day
- Combined with daily automation, it updates itself without user intervention
- The visual "intensification" effect is something no standard countdown app/widget does
- Works great for product launches, personal milestones, or habit streaks

**Implementation (P1):**
- New `CountdownConfig: Codable` struct: targetDate, label, style
- New case in `PanelType`: `.countdown`
- Panel builder: calculates days remaining from current date, formats display
- Optional: theme modifier that adjusts accent saturation based on proximity to target
