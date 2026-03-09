# Lock Screen Studio — UI/UX Wireframe Descriptions

## Design Tokens

```
Typography:
  - Display:    .largeTitle (34pt, bold)
  - Headline:   .title2 (22pt, bold)
  - Subhead:    .headline (17pt, semibold)
  - Body:       .body (17pt, regular)
  - Caption:    .caption (12pt, regular)
  - Micro:      .caption2 (11pt, regular)

Spacing:
  - xs: 4pt
  - sm: 8pt
  - md: 16pt
  - lg: 24pt
  - xl: 32pt
  - xxl: 48pt

Corner Radius:
  - Small: 8pt  (buttons, tags)
  - Medium: 12pt (cards, panels)
  - Large: 16pt (sheets, modals)
  - XLarge: 24pt (template previews)

Shadows:
  - Subtle: 0 2 8 rgba(0,0,0,0.06)  — cards
  - Medium: 0 4 16 rgba(0,0,0,0.10) — elevated elements
  - None used elsewhere (keep minimal)

Colors:
  - Primary: system blue (adaptable accent)
  - Background: .systemBackground / .systemGroupedBackground
  - Surface: .secondarySystemBackground
  - Text Primary: .label
  - Text Secondary: .secondaryLabel
  - Accent presets: Indigo, Teal, Orange, Rose (Pro)
```

---

## Screen 1: Onboarding

### Layout
Three horizontally-paged screens with bottom "Continue" button and page dots.

### Screen 1A — Value Prop
```
┌─────────────────────────┐
│                         │
│    [Hero Illustration]  │
│    Phone with wallpaper  │
│                         │
│   Your Lock Screen,     │
│   Your Dashboard.       │
│                         │
│   See today's agenda,   │
│   priorities & habits   │
│   at a glance.          │
│                         │
│                         │
│   ┌───────────────────┐ │
│   │    Get Started     │ │
│   └───────────────────┘ │
│         · · ·           │
└─────────────────────────┘
```

### Screen 1B — Permissions
```
┌─────────────────────────┐
│                         │
│   [Calendar Icon]       │
│                         │
│   Quick Setup           │
│                         │
│   ┌───────────────────┐ │
│   │ 📅 Calendar Access │ │
│   │ See your events    │ │
│   │ on your wallpaper  │ │
│   │        [Allow]     │ │
│   └───────────────────┘ │
│                         │
│   ┌───────────────────┐ │
│   │ ✓ Reminders       │ │
│   │ Optional · Skip → │ │
│   └───────────────────┘ │
│                         │
│   🔒 Everything stays   │
│   on your device.       │
│   No account needed.    │
│                         │
│   ┌───────────────────┐ │
│   │     Continue       │ │
│   └───────────────────┘ │
│         · · ·           │
└─────────────────────────┘
```

**Microcopy:**
- "We only read your calendar to show events on your wallpaper. Nothing leaves your device."
- "Reminders are optional — you can enable them later in Settings."

### Screen 1C — First Template
```
┌─────────────────────────┐
│                         │
│   Pick Your First Look  │
│                         │
│   ┌─────┐  ┌─────┐     │
│   │Today│  │Minim│     │
│   │Dash │  │ al  │     │
│   │     │  │     │     │
│   │ ✓   │  │     │     │
│   └─────┘  └─────┘     │
│                         │
│   ┌─────┐  ┌─────┐     │
│   │Priori│  │Focus│     │
│   │ties  │  │Dark │     │
│   │  🔒  │  │ 🔒  │     │
│   └─────┘  └─────┘     │
│                         │
│   🔒 = Pro templates    │
│                         │
│   ┌───────────────────┐ │
│   │  Start Creating    │ │
│   └───────────────────┘ │
│         · · ·           │
└─────────────────────────┘
```

---

## Screen 2: Template Gallery (Home)

### Layout
- Navigation bar: "Lock Screen Studio" title, settings gear icon (trailing)
- Scrollable grid of template cards (2 columns)
- Each card: preview thumbnail, template name, panel count badge
- Pro templates show lock icon overlay
- Bottom: floating "Create New" button (Pro, vNext)

```
┌─────────────────────────┐
│ Lock Screen Studio  ⚙️   │
├─────────────────────────┤
│                         │
│  Your Templates         │
│                         │
│  ┌─────────┐ ┌────────┐│
│  │ [preview]│ │[preview]││
│  │         │ │        ││
│  │ Today   │ │Minimal ││
│  │ Dash    │ │Agenda  ││
│  │ 4 panels│ │2 panels││
│  └─────────┘ └────────┘│
│                         │
│  ┌─────────┐ ┌────────┐│
│  │ [preview]│ │[preview]││
│  │   🔒    │ │  🔒    ││
│  │Priority │ │Weekly  ││
│  │ Focus   │ │Overview││
│  └─────────┘ └────────┘│
│                         │
│  ┌─────────┐ ┌────────┐│
│  │ [preview]│ │[preview]││
│  │   🔒    │ │  🔒    ││
│  │ Split   │ │Dark    ││
│  │ Layout  │ │Focus   ││
│  └─────────┘ └────────┘│
│                         │
└─────────────────────────┘
```

**Actions:**
- Tap template → Editor screen
- Tap Pro template → Paywall (or Editor with upgrade prompt)
- Tap gear → Settings
- Long-press template → context menu (Duplicate, Delete if custom)

---

## Screen 3: Editor

### Layout
- Navigation: back arrow, template name (editable), "Preview" button
- Panels list (reorderable via drag handles)
- Each panel row: icon, name, toggle (visible/hidden), chevron for config
- Bottom toolbar: Theme picker button, "Generate" primary button

```
┌─────────────────────────┐
│ ← Today Dashboard  👁️   │
├─────────────────────────┤
│                         │
│  Panels                 │
│  ┌─────────────────────┐│
│  │ ≡ 📅 Agenda    [on] >││
│  ├─────────────────────┤│
│  │ ≡ ⭐ Top 3     [on] >││
│  ├─────────────────────┤│
│  │ ≡ 📋 To-Do     [on] >││
│  ├─────────────────────┤│
│  │ ≡ 📆 Date/Time [on] >││
│  └─────────────────────┘│
│                         │
│  + Add Panel             │
│                         │
│  ┌─────────────────────┐│
│  │ Quick Edit           ││
│  │                     ││
│  │ Priority 1:         ││
│  │ [Ship v1.0        ] ││
│  │ Priority 2:         ││
│  │ [Review PRs        ] ││
│  │ Priority 3:         ││
│  │ [Gym at 6pm        ] ││
│  └─────────────────────┘│
│                         │
│  ┌──────┐               │
│  │🎨Theme│               │
│  └──────┘               │
│                         │
│  ┌───────────────────┐  │
│  │    Generate ▶      │  │
│  └───────────────────┘  │
└─────────────────────────┘
```

**Panel Config Sheet (chevron tap):**
- Agenda: date range (today/tomorrow/week), max events, show time toggle
- Top 3: edit 3 priority text fields
- To-Do: manage items list (add/remove/reorder)
- Date/Time: format options, show day-of-week toggle

**Theme Picker (bottom sheet):**
- Grid of theme previews (Light, Dark, + 4 accent colors)
- Pro badge on premium themes
- Live preview updates as user taps

---

## Screen 4: Preview

### Layout
- Full-screen preview of generated wallpaper
- Device frame overlay (optional, toggle)
- Safe area overlay toggle (shows clock zone, Dynamic Island, bottom bar)
- Bottom: "Export" button, "Back to Edit" link

```
┌─────────────────────────┐
│ ← Preview     [Safe ◻️]  │
├─────────────────────────┤
│                         │
│   ┌─────────────────┐   │
│   │  ╭─────────╮    │   │
│   │  │ 9:41    │    │   │
│   │  │┈┈┈┈┈┈┈┈┈│    │   │
│   │  │         │    │   │
│   │  │ TUESDAY │    │   │
│   │  │ Feb 20  │    │   │
│   │  │         │    │   │
│   │  │ ━━━━━━━ │    │   │
│   │  │ 9:00 Standup│   │
│   │  │10:00 Design │    │
│   │  │14:00 Review │    │
│   │  │         │    │   │
│   │  │ TOP 3   │    │   │
│   │  │ 1.Ship v1│    │   │
│   │  │ 2.Review │    │   │
│   │  │ 3.Gym   │    │   │
│   │  │         │    │   │
│   │  ╰─────────╯    │   │
│   └─────────────────┘   │
│                         │
│  Device: iPhone 15 Pro ▾│
│                         │
│  ┌───────────────────┐  │
│  │      Export        │  │
│  └───────────────────┘  │
└─────────────────────────┘
```

**Safe Area Overlay (when toggled on):**
- Semi-transparent red zone over clock area (top 120pt)
- Dynamic Island cutout indicator
- Bottom home indicator zone
- Label: "Content in red zones may be obscured"

---

## Screen 5: Export

### Layout
- Resolution picker (device presets dropdown)
- Format toggle (PNG / JPEG)
- Quality slider (JPEG only)
- Action buttons: Save to Photos, Share, Copy

```
┌─────────────────────────┐
│ ← Export                 │
├─────────────────────────┤
│                         │
│  ┌─────────────────────┐│
│  │   [Wallpaper thumb] ││
│  │                     ││
│  │   1290 × 2796 px    ││
│  └─────────────────────┘│
│                         │
│  Device Preset          │
│  ┌─────────────────────┐│
│  │ iPhone 15 Pro    ▾  ││
│  └─────────────────────┘│
│                         │
│  Format                 │
│  ┌──────┐ ┌──────┐     │
│  │ PNG  │ │ JPEG │     │
│  │  ●   │ │  ○   │     │
│  └──────┘ └──────┘     │
│                         │
│  ┌───────────────────┐  │
│  │  💾 Save to Photos │  │
│  └───────────────────┘  │
│  ┌───────────────────┐  │
│  │  📤 Share          │  │
│  └───────────────────┘  │
│  ┌───────────────────┐  │
│  │  📋 Copy           │  │
│  └───────────────────┘  │
│                         │
│  Free: 2 of 3 exports   │
│  remaining today         │
│                         │
└─────────────────────────┘
```

---

## Screen 6: Paywall

### Layout
- Hero: blurred Pro template preview behind glass effect
- Feature comparison list
- Plan cards (monthly / yearly with savings badge)
- "Start Free Trial" primary CTA
- "Restore Purchases" link
- Dismiss X button (top-right)

```
┌─────────────────────────┐
│                      ✕  │
├─────────────────────────┤
│                         │
│   [Blurred Pro preview] │
│                         │
│   Unlock Your Full      │
│   Dashboard             │
│                         │
│   ✓ All templates       │
│   ✓ Unlimited exports   │
│   ✓ Premium themes      │
│   ✓ Full Shortcuts      │
│     automation          │
│   ✓ Advanced typography │
│                         │
│  ┌─────────────────────┐│
│  │   Monthly           ││
│  │   €2.99/month       ││
│  └─────────────────────┘│
│  ┌─────────────────────┐│
│  │ ⭐ Yearly   SAVE 44% ││
│  │   €19.99/year       ││
│  │   3-day free trial  ││
│  └─────────────────────┘│
│                         │
│  ┌───────────────────┐  │
│  │ Start Free Trial   │  │
│  └───────────────────┘  │
│                         │
│  Restore Purchases      │
│  Terms · Privacy        │
│                         │
└─────────────────────────┘
```

**Microcopy:**
- "Try Pro free for 3 days. Cancel anytime."
- "Your data never leaves your device — even with Pro."
- "Payment is charged to your Apple ID account."

---

## Screen 7: Settings

### Layout
- Grouped list style (insetGrouped)

```
┌─────────────────────────┐
│ ← Settings               │
├─────────────────────────┤
│                         │
│  APPEARANCE             │
│  ┌─────────────────────┐│
│  │ Theme     System ▾  ││
│  │ Accent    Indigo ▾  ││
│  └─────────────────────┘│
│                         │
│  DEFAULTS               │
│  ┌─────────────────────┐│
│  │ Default Template  ▾ ││
│  │ Default Device   ▾  ││
│  └─────────────────────┘│
│                         │
│  DATA                   │
│  ┌─────────────────────┐│
│  │ Calendar Access   ✓ ││
│  │ Reminders Access  ○ ││
│  └─────────────────────┘│
│                         │
│  SHORTCUTS              │
│  ┌─────────────────────┐│
│  │ Shortcuts Guide   > ││
│  │ Install Shortcuts > ││
│  └─────────────────────┘│
│                         │
│  SUBSCRIPTION           │
│  ┌─────────────────────┐│
│  │ Plan: Free          ││
│  │ Upgrade to Pro    > ││
│  │ Restore Purchases > ││
│  └─────────────────────┘│
│                         │
│  ABOUT                  │
│  ┌─────────────────────┐│
│  │ Version 1.0 (1)     ││
│  │ Privacy Policy    > ││
│  │ Terms of Service  > ││
│  │ Acknowledgments   > ││
│  └─────────────────────┘│
│                         │
└─────────────────────────┘
```

---

## Accessibility Notes

- All interactive elements have `.accessibilityLabel` and `.accessibilityHint`
- Template gallery cards: "Today Dashboard template, 4 panels. Double tap to edit."
- Safe area toggle: "Safe area overlay, currently off. Double tap to show excluded zones."
- Panel reorder: supports `.accessibilityAction(.move)` for VoiceOver reordering
- All text scales with Dynamic Type (up to .accessibility3)
- Minimum touch target: 44x44pt
- Color contrast: all text meets WCAG AA (4.5:1 for body, 3:1 for large text)
- Paywall: all pricing info accessible, "Start Free Trial" clearly labeled
