import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct LockScreenStudioApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private let backgroundTaskManager = BackgroundTaskManager.shared

    let sharedModelContainer: ModelContainer = SharedContainer.makeModelContainer()

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
