import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appTheme: String = "auto"
    @AppStorage("selectedAccent") private var selectedAccent: String = "indigo"

    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = false
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval: Double = 24
    @AppStorage("automationMode") private var automationMode: String = "off" // off | builtin | shortcuts

    @State private var calendarAuthorized = false
    @State private var showPaywall = false
    @State private var showShortcutsGuide = false

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                automationSection
                dataSection
                subscriptionSection
                aboutSection
                #if DEBUG
                debugSection
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showShortcutsGuide) {
                ShortcutsGuideView()
            }
            .task { await checkCalendarAccess() }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appTheme) {
                Text("System").tag("auto")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }

            Picker("Accent Color", selection: $selectedAccent) {
                ForEach(AccentColorOption.allCases) { option in
                    HStack {
                        Circle()
                            .fill(option.color)
                            .frame(width: 16, height: 16)
                        Text(option.rawValue.capitalized)
                        if option.isPro && !subscriptionManager.isPro {
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.indigo)
                        }
                    }
                    .tag(option.rawValue)
                }
            }
            .onChange(of: selectedAccent) { _, newValue in
                if let option = AccentColorOption(rawValue: newValue),
                   option.isPro && !subscriptionManager.isPro {
                    selectedAccent = "indigo"
                    showPaywall = true
                }
            }
        }
    }

    // MARK: - Automation (unified BGTask + Shortcuts surface)

    private var automationSection: some View {
        Section {
            Picker("Mode", selection: $automationMode) {
                Text("Off").tag("off")
                Text("Built-in").tag("builtin")
                Text("Shortcuts (recommended)").tag("shortcuts")
            }
            .onChange(of: automationMode) { _, newValue in
                applyAutomationMode(newValue)
            }

            if automationMode == "builtin" {
                Picker("Frequency", selection: $autoRefreshInterval) {
                    Text("Every 6 hours").tag(6.0)
                    Text("Every 12 hours").tag(12.0)
                    Text("Daily").tag(24.0)
                    Text("Every 2 days").tag(48.0)
                }
                .onChange(of: autoRefreshInterval) { _, _ in
                    BackgroundTaskManager.shared.cancelScheduledRefresh()
                    BackgroundTaskManager.shared.scheduleRefreshIfEnabled()
                }
            }

            if automationMode == "shortcuts" {
                Button {
                    showShortcutsGuide = true
                } label: {
                    Label("Open Automation Gallery", systemImage: "bolt.fill")
                }
            }
        } header: {
            Text("Automation")
        } footer: {
            Text(automationFooter)
        }
    }

    private var automationFooter: String {
        switch automationMode {
        case "builtin":
            return "iOS picks an opportune moment within your chosen window - exact timing isn't guaranteed. A fresh wallpaper is saved to Photos with a notification - tap once to apply. For precise scheduling (e.g. 7:00 AM sharp), use Shortcuts instead."
        case "shortcuts":
            return "Pick a ready-made automation - morning refresh, alarm trigger, focus-mode theme switch - and run it exactly when you specify. The fresh wallpaper lands in Photos with a notification; one tap to apply. (Apple removed direct wallpaper-setting from Shortcuts in iOS 26.)"
        default:
            return "Off: your wallpaper won't update on its own. Pick Built-in for fire-and-forget, or Shortcuts for precise scheduling."
        }
    }

    private func applyAutomationMode(_ mode: String) {
        switch mode {
        case "builtin":
            autoRefreshEnabled = true
            Task {
                _ = await BackgroundTaskManager.shared.requestNotificationPermission()
            }
            BackgroundTaskManager.shared.scheduleRefreshIfEnabled()
        case "shortcuts":
            // BGTask path off, but we still need notifications because the
            // entire post-iOS-26 flow is: automation runs → notification
            // arrives → user taps to apply. Without notification permission
            // the user has no idea their wallpaper is ready.
            autoRefreshEnabled = false
            BackgroundTaskManager.shared.cancelScheduledRefresh()
            Task {
                _ = await BackgroundTaskManager.shared.requestNotificationPermission()
            }
        default:
            autoRefreshEnabled = false
            BackgroundTaskManager.shared.cancelScheduledRefresh()
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data") {
            HStack {
                Label("Calendar Access", systemImage: "calendar")
                Spacer()
                if calendarAuthorized {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Enable") {
                        Task {
                            let service = CalendarService()
                            calendarAuthorized = await service.requestAccess()
                        }
                    }
                    .font(.subheadline)
                }
            }

            NavigationLink {
                ExportHistoryView()
            } label: {
                Label("Export History", systemImage: "clock.arrow.circlepath")
            }
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        Section("Subscription") {
            HStack {
                Text("Plan")
                Spacer()
                Text(subscriptionManager.isPro ? "Pro" : "Free")
                    .foregroundStyle(.secondary)
            }

            if !subscriptionManager.isPro {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "sparkles")
                        .foregroundStyle(.indigo)
                }
            }

            Button {
                Task { await subscriptionManager.restorePurchases() }
            } label: {
                Text("Restore Purchases")
            }

            if subscriptionManager.isPro {
                Button {
                    // Open subscription management
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Manage Subscription")
                }
            }
        }
    }

    // MARK: - Debug (only in DEBUG builds)

    #if DEBUG
    @AppStorage("debug_force_pro") private var debugForcePro = false

    private var debugSection: some View {
        Section("Debug") {
            Toggle("Force Pro", isOn: $debugForcePro)
        }
    }
    #endif

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.appVersion)
                    .foregroundStyle(.secondary)
            }

            Link("Privacy Policy", destination: URL(string: "https://lockscreenstudio.app/privacy")!)
            Link("Terms of Service", destination: URL(string: "https://lockscreenstudio.app/terms")!)
        }
    }

    // MARK: - Helpers

    private func checkCalendarAccess() async {
        let service = CalendarService()
        calendarAuthorized = await service.authorizationStatus == .authorized
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
        .environmentObject(SubscriptionManager())
}
