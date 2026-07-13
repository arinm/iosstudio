# Dormant product analytics foundation

The app keeps a vendor-neutral event layer in `AnalyticsService.swift`, but no
network analytics provider is linked or configured. Release builds discard all
events. Debug builds write them only to Apple's unified logging on the local
development device.

There is intentionally no analytics disclosure or toggle in the product while
no data leaves the device. Before a network provider is added in the future, we
must design explicit consent for both new and existing users, update the privacy
policy and App Store privacy answers, and add provider-specific tests.

## Funnel definitions

| Metric | Definition | Events |
| --- | --- | --- |
| Acquisition quality | Store page conversion and first opens | App Store Connect + `app_opened` |
| Activation | User completes onboarding and saves the first wallpaper | `onboarding_completed` → first `export_completed` |
| Engagement | User opens templates and exports wallpapers | `template_opened`, `export_completed` |
| Retention | Unique active installs returning on later days | daily unique `app_opened` after a provider is enabled |
| Monetization | Paywall-to-purchase conversion | `paywall_viewed` → `purchase_started` → `purchase_completed` |

## Event rules

- Properties must be low-cardinality strings.
- Never include template names, task text, calendar event data, photo data,
  free-form errors, email addresses, or other personal content.
- Built-in templates use `builtInKey`; custom templates use the literal
  `custom` value.
- Purchase events may include Apple product IDs, but never transaction IDs.
- Errors use a fixed stage/category, never `localizedDescription`.

## Initial event catalog

- `app_opened`
- `onboarding_completed`
- `template_opened`
- `custom_template_created`
- `export_started`, `export_completed`, `export_failed`
- `paywall_viewed`
- `purchase_started`, `purchase_completed`, `purchase_not_completed`,
  `purchase_failed`
- `restore_started`, `restore_completed`, `restore_no_purchases`,
  `restore_failed`
