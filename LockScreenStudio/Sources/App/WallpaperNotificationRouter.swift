import Foundation
import UIKit
import UserNotifications

/// Routes taps on wallpaper notifications: a successful-refresh tap jumps the
/// user straight into Photos (removing a step from the daily apply loop);
/// a permission-problem tap opens the app's Settings page so they can fix it.
/// Must be installed as the notification-center delegate before launch
/// finishes — see `LockScreenStudioApp.init`.
final class WallpaperNotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WallpaperNotificationRouter()

    /// Installs the router as the shared notification-center delegate.
    static func install() {
        UNUserNotificationCenter.current().delegate = shared
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let rawOutcome = userInfo[WallpaperNotification.outcomeUserInfoKey] as? String,
              let outcome = WallpaperNotification.Outcome(rawValue: rawOutcome) else {
            return
        }

        let url: URL? = switch outcome {
        case .savedToPhotos: URL(string: "photos-redirect://")
        case .photosPermissionDenied: URL(string: UIApplication.openSettingsURLString)
        }

        if let url {
            await MainActor.run { UIApplication.shared.open(url) }
        }
    }

    /// Show the banner even when the app is foreground — useful when the user
    /// test-runs their automation from the guide and switches right back.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
