import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var currentPage = 0
    @State private var calendarGranted = false
    @State private var selectedTemplate: String? = "Today Dashboard"

    @State private var demoPreviewImage: UIImage?

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            previewDemoPage.tag(1)
            permissionsPage.tag(2)
            templatePage.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(Color(.systemBackground))
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(.indigo)

            VStack(spacing: 12) {
                Text("Your Lock Screen,\nYour Dashboard.")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("See today's agenda, priorities & habits at a glance — right on your Lock Screen.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Page 2: Preview Demo

    private var previewDemoPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("See It in Action")
                .font(.title.bold())

            Text("A real-time preview of your wallpaper, generated right on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let image = demoPreviewImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                    .padding(.horizontal, 48)
            } else {
                ProgressView()
                    .frame(height: 320)
            }

            Spacer()

            Button {
                withAnimation { currentPage = 2 }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .task { await generateDemoPreview() }
    }

    @MainActor
    private func generateDemoPreview() async {
        let panels = [
            PanelRenderData(title: nil, lines: [
                .text("FRIDAY"),
                .text("February 21, 2026"),
            ]),
            PanelRenderData(title: "AGENDA", lines: [
                .event(time: "09:00", title: "Team Standup"),
                .event(time: "10:30", title: "Design Review"),
                .event(time: "14:00", title: "Sprint Planning"),
            ]),
            PanelRenderData(title: "TOP 3", lines: [
                .priority(rank: 1, text: "Ship v1.0"),
                .priority(rank: 2, text: "Review pull requests"),
                .priority(rank: 3, text: "Gym at 6pm"),
            ]),
        ]

        let renderer = WallpaperRenderer()
        let preset = DevicePreset.current
        demoPreviewImage = try? renderer.renderPreview(
            panels: panels,
            theme: .defaultDark,
            devicePreset: preset
        )
    }

    // MARK: - Page 3: Permissions

    private var permissionsPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 60, weight: .thin))
                .foregroundStyle(.indigo)

            Text("Quick Setup")
                .font(.title.bold())

            VStack(spacing: 16) {
                permissionRow(
                    icon: "calendar",
                    title: "Calendar Access",
                    subtitle: "See your events on your wallpaper",
                    granted: calendarGranted
                ) {
                    Task {
                        let service = CalendarService()
                        calendarGranted = await service.requestAccess()
                    }
                }

                HStack {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Everything stays on your device. No account needed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                withAnimation { currentPage = 3 }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        subtitle: String,
        granted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.indigo)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            } else {
                Button("Allow", action: action)
                    .buttonStyle(.bordered)
                    .tint(.indigo)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Page 3: Pick Template

    private var templatePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Pick Your First Look")
                .font(.title.bold())

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
            ], spacing: 16) {
                templateCard("Today Dashboard", icon: "calendar.badge.clock", isPro: false)
                templateCard("Minimal Agenda", icon: "list.bullet", isPro: false)
                templateCard("Priority Focus", icon: "star.fill", isPro: true)
                templateCard("Dark Focus", icon: "moon.fill", isPro: true)
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("Start Creating")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func templateCard(_ name: String, icon: String, isPro: Bool) -> some View {
        let locked = isPro && !subscriptionManager.isPro
        return VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: 120)

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(locked ? Color.secondary : Color.indigo)

                if locked {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedTemplate == name ? Color.indigo : .clear, lineWidth: 2)
            )

            Text(name)
                .font(.caption)
                .fontWeight(selectedTemplate == name ? .semibold : .regular)
        }
        .onTapGesture {
            if !locked {
                selectedTemplate = name
            }
        }
        .accessibilityLabel("\(name) template\(locked ? ", Pro required" : "")")
        .accessibilityAddTraits(selectedTemplate == name ? .isSelected : [])
    }
}

#Preview {
    OnboardingView { }
}
