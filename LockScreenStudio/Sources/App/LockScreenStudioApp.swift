import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct LockScreenStudioApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var templateImportCoordinator = TemplateImportCoordinator()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private let backgroundTaskManager = BackgroundTaskManager.shared

    let sharedModelContainer: ModelContainer = SharedContainer.makeModelContainer()

    init() {
        // Must be installed before launch finishes so cold-start notification
        // taps are routed (straight to Photos on a successful refresh).
        WallpaperNotificationRouter.install()
        migrateAutomationModeIfNeeded()
        AnalyticsService.shared.track(
            .appOpened,
            properties: [
                "onboarding_completed": String(
                    UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                )
            ]
        )
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView {
                        AnalyticsService.shared.track(.onboardingCompleted)
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
            .environmentObject(subscriptionManager)
            .environmentObject(templateImportCoordinator)
            .onAppear {
                backgroundTaskManager.registerTasks()
                backgroundTaskManager.scheduleRefreshIfEnabled()
            }
            .onOpenURL { url in
                guard url.pathExtension.lowercased() == "lockscreenstudio" else { return }
                templateImportCoordinator.enqueue(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }

    /// One-time bridge for users upgrading from v1.10 or earlier: their
    /// `autoRefreshEnabled` may be true (BGTask scheduled) while the new
    /// `automationMode` key would default to "off", producing a confusing UI
    /// state where Settings says Off but the background task keeps firing.
    private func migrateAutomationModeIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "automationModeMigrated") else { return }
        if defaults.bool(forKey: "autoRefreshEnabled") {
            defaults.set("builtin", forKey: "automationMode")
        }
        defaults.set(true, forKey: "automationModeMigrated")
    }
}
