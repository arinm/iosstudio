import Foundation
import UserNotifications

/// Sends the "Wallpaper Updated" notification used to nudge the user to apply
/// the freshly-generated wallpaper from Photos.
///
/// Shared between the BGTask path (`BackgroundTaskManager`) and the AppIntents
/// (`WallpaperIntents`) so the messaging stays consistent.
enum WallpaperNotification {

    /// What happened during the wallpaper generation. Drives notification copy
    /// so the user gets actionable feedback instead of a useless "go open Photos
    /// to find nothing" prompt when Photos permission is missing.
    enum Outcome {
        case savedToPhotos
        case photosPermissionDenied
    }

    /// Posts a "Wallpaper Updated" notification. Best-effort — silently no-ops
    /// if the user has denied notifications. Requests permission first if the
    /// status is `.notDetermined`.
    static func sendRefreshed(outcome: Outcome = .savedToPhotos) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }

        let updated = await center.notificationSettings()
        guard updated.authorizationStatus == .authorized
            || updated.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        switch outcome {
        case .savedToPhotos:
            content.title = "Wallpaper Updated"
            content.body = "Tap to open Photos and apply your fresh Lock Screen."
        case .photosPermissionDenied:
            content.title = "Lock Screen Studio needs Photos access"
            content.body = "Your fresh wallpaper was generated but couldn't be saved. Open Settings > Privacy > Photos and allow Add Only access."
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "wallpaper-refresh-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }
}
