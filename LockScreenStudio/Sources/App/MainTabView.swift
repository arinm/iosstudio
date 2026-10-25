import SwiftUI
import StoreKit

struct MainTabView: View {
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            TemplateGalleryView()
        }
        .task { await askForReviewIfAutomationHasProvedItself() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await askForReviewIfAutomationHasProvedItself() }
            }
        }
    }

    /// Checked on every return to the foreground, because the moment that
    /// matters — the automation has already refreshed the wallpaper on a
    /// second morning — happens while the app is closed.
    private func askForReviewIfAutomationHasProvedItself() async {
        // Let the app finish appearing first; a prompt over a launch
        // transition reads as an interruption, not a question.
        do { try await Task.sleep(for: .seconds(2)) } catch { return }
        // Checked after the wait, not before: asking spends this version's one
        // prompt, and an app that was closed in those two seconds would spend
        // it on nobody.
        guard UIApplication.shared.applicationState == .active else { return }
        guard ReviewRequestManager.shouldPromptAfterAutomation(
            firstRun: AutomationStatus.firstRunDate(),
            lastRun: AutomationStatus.lastRunDate
        ) else { return }
        requestReview()
    }
}

#Preview {
    MainTabView()
        .environmentObject(SubscriptionManager())
        .environmentObject(TemplateImportCoordinator())
}
