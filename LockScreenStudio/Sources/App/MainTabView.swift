import SwiftUI

struct MainTabView: View {
    var body: some View {
        NavigationStack {
            TemplateGalleryView()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(SubscriptionManager())
}
