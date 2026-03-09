# LockScreenStudio — Future Improvements

## Haptic Feedback
- Add subtle haptic feedback (UIImpactFeedbackGenerator) on button taps and selections
- Theme picker: light impact on color/gradient selection
- Editor: medium impact on panel toggle, light on reorder
- Export: success notification feedback on save
- Use `.sensoryFeedback()` modifier (iOS 17+) where possible

## Duplicate Template
- Add "Duplicate" button in template gallery (long-press context menu or swipe action)
- Creates a copy of the template with name "[Original] Copy" and all panels/configs duplicated
- New template is not built-in (user-created), so it can be renamed/deleted freely

## Landing Page — Pre-Deploy Checklist

- [ ] Add real app screenshots to `website/public/screenshots/` and update `PhoneMockup.tsx`
- [ ] Replace `href="#"` download buttons with real App Store link
- [ ] Replace `app/favicon.ico` with app icon
- [ ] Add Open Graph image (`og-image.png`) for social sharing
- [ ] Review Privacy Policy and Terms of Service content
- [ ] Deploy to Vercel (`cd website && npx vercel` or connect repo on vercel.com)

## Other Ideas
- Weather panel type (requires WeatherKit or API integration)
- iCloud sync for templates and settings across devices
- Widget showing when wallpaper was last updated
- Scheduled auto-refresh using BackgroundTasks framework
