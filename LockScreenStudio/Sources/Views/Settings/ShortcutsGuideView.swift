import SwiftUI

struct ShortcutsGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    introSection
                    shortcutsList
                    setupSteps
                    tipsSection
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Shortcuts Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Intro

    private var introSection: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bolt.circle.fill")
                .font(.title2)
                .foregroundStyle(.indigo)

            Text("Lock Screen Studio works with Apple Shortcuts to automatically update your wallpaper every morning — or whenever you want.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Available Shortcuts

    private var shortcutsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available Actions")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            shortcutCard(
                name: "Generate Today Wallpaper",
                description: "Creates a wallpaper with today's data using your default template.",
                tier: "Free"
            )

            shortcutCard(
                name: "Generate Wallpaper",
                description: "Choose a specific template and theme.",
                tier: "Pro"
            )

            shortcutCard(
                name: "Generate Wallpaper (Advanced)",
                description: "Full control: date, device, format, and template.",
                tier: "Pro"
            )
        }
    }

    private func shortcutCard(name: String, description: String, tier: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline.bold())
                Spacer()
                Text(tier)
                    .font(.caption2.bold())
                    .foregroundStyle(tier == "Free" ? .green : .indigo)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        (tier == "Free" ? Color.green : Color.indigo).opacity(0.1)
                    )
                    .clipShape(Capsule())
            }
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Setup Steps

    private var setupSteps: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set Up Daily Automation")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            stepRow(number: 1, text: "Open the **Shortcuts** app")
            stepRow(number: 2, text: "Create a new **Automation**")
            stepRow(number: 3, text: "Choose **Time of Day** (e.g., 6:00 AM)")
            stepRow(number: 4, text: "Add action: **Generate Today Wallpaper**")
            stepRow(number: 5, text: "Add action: **Set Wallpaper** (use the output from step 4)")
            stepRow(number: 6, text: "Set to **Run Immediately** (no confirmation)")
        }
    }

    private func stepRow(number: Int, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.indigo)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Tips

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tips")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

            tipRow(icon: "clock", text: "Set your automation for 5-10 minutes after your alarm so the wallpaper is ready when you check your phone.")
            tipRow(icon: "moon.fill", text: "Create separate automations for morning (work mode) and evening (personal mode).")
            tipRow(icon: "bolt.fill", text: "Generation is fast — under 1 second — so automations won't delay your morning.")
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.indigo)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Shortcuts Wizard (compact 3-step version for Editor)

struct ShortcutsWizardSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.indigo)

                        Text("Daily Auto-Generate")
                            .font(.title3.bold())
                        Text("Set up a Shortcut to generate a fresh wallpaper every morning — then apply it with one tap.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // 3 Steps
                    VStack(alignment: .leading, spacing: 16) {
                        wizardStep(
                            number: 1,
                            icon: "app.badge",
                            title: "Open Shortcuts",
                            detail: "Open Apple's **Shortcuts** app and create a new **Automation**. Choose **Time of Day** (e.g. 6:00 AM)."
                        )
                        wizardStep(
                            number: 2,
                            icon: "wand.and.stars",
                            title: "Add Generate Action",
                            detail: "Search for **\"Generate Today Wallpaper\"** and add it. This creates a fresh image with your current data."
                        )
                        wizardStep(
                            number: 3,
                            icon: "photo.on.rectangle",
                            title: "Set Wallpaper",
                            detail: "Add a **\"Set Wallpaper\"** action after it, using the generated image. Set to **Run Immediately**."
                        )
                    }
                    .padding(.horizontal, 4)

                    // Note
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("iOS may ask for confirmation the first time. After that, it runs silently every morning.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Open Shortcuts button
                    Button {
                        if let url = URL(string: "shortcuts://") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.forward.app")
                            Text("Open Shortcuts App")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                .padding(20)
            }
            .navigationTitle("Setup Automation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func wizardStep(number: Int, icon: String, title: String, detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.indigo)
                    .frame(width: 36, height: 36)
                Text("\(number)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(.indigo)
                    Text(title)
                        .font(.subheadline.bold())
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview("Guide") {
    ShortcutsGuideView()
        .environmentObject(SubscriptionManager())
}

#Preview("Wizard") {
    ShortcutsWizardSheet()
}
