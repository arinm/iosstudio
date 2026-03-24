import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appTheme: String = "auto"
    @AppStorage("defaultAccent") private var defaultAccent: String = "indigo"

    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = false
    @AppStorage("autoRefreshInterval") private var autoRefreshInterval: Double = 24

    @State private var calendarAuthorized = false
    @State private var notificationsAuthorized = false
    @State private var showPaywall = false
    @State private var showShortcutsGuide = false
    @State private var currentIcon: AppIconOption = .default

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                autoRefreshSection
                dataSection
                shortcutsSection
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
            .onAppear { detectCurrentIcon() }
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

            Picker("Accent Color", selection: $defaultAccent) {
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
            .onChange(of: defaultAccent) { _, newValue in
                if let option = AccentColorOption(rawValue: newValue),
                   option.isPro && !subscriptionManager.isPro {
                    defaultAccent = "indigo"
                    showPaywall = true
                }
            }
        }
    }

    // MARK: - App Icon

    private var appIconSection: some View {
        Section("App Icon") {
            ForEach(AppIconOption.allCases) { option in
                let isLocked = option.isPro && !subscriptionManager.isPro
                let isSelected = currentIcon == option

                Button {
                    guard !isLocked else {
                        showPaywall = true
                        return
                    }
                    setAppIcon(option)
                } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(option.previewColor))
                            .frame(width: 44, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .overlay {
                                Image(systemName: "rectangle.on.rectangle.angled")
                                    .font(.caption)
                                    .foregroundStyle(option.useDarkIcon ? .black : .white)
                            }

                        Text(option.displayName)
                            .foregroundStyle(.primary)

                        Spacer()

                        if isLocked {
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.indigo)
                        }
                        if isSelected {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.indigo)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func setAppIcon(_ option: AppIconOption) {
        UIApplication.shared.setAlternateIconName(option.alternateIconName) { error in
            if error == nil {
                currentIcon = option
            }
        }
    }

    private func detectCurrentIcon() {
        let iconName = UIApplication.shared.alternateIconName
        currentIcon = AppIconOption.allCases.first { $0.alternateIconName == iconName } ?? .default
    }

    // MARK: - Auto Refresh

    private var autoRefreshSection: some View {
        Section {
            Toggle("Auto-Refresh Wallpaper", isOn: $autoRefreshEnabled)
                .onChange(of: autoRefreshEnabled) { _, enabled in
                    if enabled {
                        Task {
                            notificationsAuthorized = await BackgroundTaskManager.shared.requestNotificationPermission()
                        }
                        BackgroundTaskManager.shared.scheduleRefreshIfEnabled()
                    } else {
                        BackgroundTaskManager.shared.cancelScheduledRefresh()
                    }
                }

            if autoRefreshEnabled {
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
        } header: {
            Text("Auto-Refresh")
        } footer: {
            Text("Automatically regenerates your wallpaper with fresh data (calendar, todos) and saves it to Photos. You'll get a notification when it's ready.")
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

    // MARK: - Shortcuts

    private var shortcutsSection: some View {
        Section("Shortcuts") {
            Button {
                showShortcutsGuide = true
            } label: {
                Label("Shortcuts Guide", systemImage: "bolt.fill")
            }

            Button {
                // Open Shortcuts app
                if let url = URL(string: "shortcuts://") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Shortcuts App", systemImage: "arrow.up.right.square")
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
