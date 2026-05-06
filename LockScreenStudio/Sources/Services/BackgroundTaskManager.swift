import BackgroundTasks
import UIKit
import Photos
import UserNotifications
import SwiftData

/// Manages background wallpaper refresh using BGProcessingTask.
/// Regenerates the wallpaper with current panel data (calendar, todos, etc.)
/// and saves it to Photos, then sends a local notification.
@MainActor
final class BackgroundTaskManager {

    static let shared = BackgroundTaskManager()
    static let taskIdentifier = "com.lockscreenstudio.wallpaper.refresh"

    private let exportService = ExportService()

    private init() {}

    // MARK: - Registration (call once at app launch)

    func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { task in
            Task { @MainActor in
                guard let processingTask = task as? BGProcessingTask else {
                    task.setTaskCompleted(success: false)
                    return
                }
                await self.handleWallpaperRefresh(task: processingTask)
            }
        }
    }

    // MARK: - Scheduling

    func scheduleRefreshIfEnabled() {
        guard UserDefaults.standard.bool(forKey: "autoRefreshEnabled") else { return }

        let request = BGProcessingTaskRequest(identifier: Self.taskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        // Schedule based on user's preferred interval
        let intervalHours = UserDefaults.standard.double(forKey: "autoRefreshInterval")
        let interval = intervalHours > 0 ? intervalHours * 3600 : 24 * 3600 // default 24h
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Scheduling failure is non-critical, silently ignored
        }
    }

    func cancelScheduledRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
    }

    // MARK: - Task Handling

    private func handleWallpaperRefresh(task: BGProcessingTask) async {
        // Schedule the next refresh before doing work
        scheduleRefreshIfEnabled()

        // Set expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        // Background path uses the saved panel snapshot; todos/priorities
        // are unavailable here and rendered as empty (BG-side limitation).
        let success = await renderAndSave(
            panels: loadSavedPanels(),
            todos: [],
            priorities: []
        )
        if success {
            await sendRefreshNotification()
        }
        task.setTaskCompleted(success: success)
    }

    /// Triggers an immediate wallpaper regeneration using the supplied data
    /// (typically called from the editor when the user toggles a todo so they
    /// see the result reflected in Photos within seconds).
    @discardableResult
    func refreshNow(
        panels: [PanelConfiguration],
        todos: [TodoItem],
        priorities: [PriorityItem]
    ) async -> Bool {
        await renderAndSave(panels: panels, todos: todos, priorities: priorities)
    }

    private func renderAndSave(
        panels: [PanelConfiguration],
        todos: [TodoItem],
        priorities: [PriorityItem]
    ) async -> Bool {
        do {
            let result = try await exportService.generateWallpaper(
                panels: panels,
                theme: nil,
                devicePreset: .current,
                priorities: priorities,
                todos: todos,
                date: .now
            )
            guard let image = UIImage(data: result.imageData) else { return false }
            try await exportService.saveToPhotos(image)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Load Panels

    /// Loads the panel configuration saved by the editor.
    /// Panels are stored as JSON in UserDefaults for background access.
    private func loadSavedPanels() -> [PanelConfiguration] {
        guard let data = UserDefaults.standard.data(forKey: "autoRefreshPanels"),
              let decoded = try? JSONDecoder().decode([PanelConfigSnapshot].self, from: data) else {
            return defaultPanels()
        }
        return decoded.map { $0.toPanelConfiguration() }
    }

    private func defaultPanels() -> [PanelConfiguration] {
        // Fallback: agenda + date/time
        [
            PanelConfiguration(panelType: .agenda, sortOrder: 0),
            PanelConfiguration(panelType: .dateTime, sortOrder: 1),
        ]
    }

    // MARK: - Notification

    private func sendRefreshNotification() async {
        let center = UNUserNotificationCenter.current()

        // Request permission if needed
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }

        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .notDetermined else { return }

        let content = UNMutableNotificationContent()
        content.title = "Wallpaper Updated"
        content.body = "Your lock screen wallpaper has been refreshed. Open Photos to apply it."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "wallpaper-refresh-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // deliver immediately
        )

        try? await center.add(request)
    }

    // MARK: - Save Panels (called from Editor)

    /// Saves the current panel configuration for background refresh.
    static func savePanelsForRefresh(_ panels: [PanelConfiguration]) {
        let snapshots = panels.map { PanelConfigSnapshot(from: $0) }
        if let data = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(data, forKey: "autoRefreshPanels")
        }
    }

    // MARK: - Notification Permission

    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
}

// MARK: - Panel Snapshot (Codable bridge for UserDefaults)

/// Lightweight Codable snapshot of PanelConfiguration for background storage.
struct PanelConfigSnapshot: Codable {
    let panelType: String
    let sortOrder: Int
    let isEnabled: Bool
    let configJSON: Data?
    let title: String?
    let showTitle: Bool

    init(from panel: PanelConfiguration) {
        self.panelType = panel.panelType.rawValue
        self.sortOrder = panel.sortOrder
        self.isEnabled = panel.isVisible
        self.configJSON = panel.configData
        self.title = panel.title
        self.showTitle = panel.showTitle
    }

    func toPanelConfiguration() -> PanelConfiguration {
        let config = PanelConfiguration(
            panelType: PanelType(rawValue: panelType) ?? .agenda,
            sortOrder: sortOrder,
            isVisible: isEnabled,
            title: title,
            configData: configJSON
        )
        config.showTitle = showTitle
        return config
    }
}
