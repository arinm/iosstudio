import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct LockScreenStudioApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private let backgroundTaskManager = BackgroundTaskManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DashboardProject.self,
            WallpaperTemplate.self,
            PanelConfiguration.self,
            ThemeConfiguration.self,
            ExportPreset.self,
            TodoItem.self,
            PriorityItem.self,
            ExportHistoryItem.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                }
            }
            .environmentObject(subscriptionManager)
            .onAppear {
                backgroundTaskManager.registerTasks()
                backgroundTaskManager.scheduleRefreshIfEnabled()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
