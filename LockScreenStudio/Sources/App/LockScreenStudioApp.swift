import SwiftUI
import SwiftData

@main
struct LockScreenStudioApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
        }
        .modelContainer(sharedModelContainer)
    }
}
