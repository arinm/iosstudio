import SwiftUI

/// Single source of truth for Shortcuts setup help. The legacy
/// `ShortcutsGuideView` and `ShortcutsWizardSheet` both render this view so
/// the Settings and Editor entry points stay in sync.
struct ShortcutsSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedRecipeID: String? = "morning"
    @State private var showMoreRecipes = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    intro
                    recommendedRecipe
                    moreRecipesDisclosure
                    customSetupDisclosure
                    tips
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Daily wallpaper automation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.indigo)
                Text("Wake up to a fresh wallpaper")
                    .font(.headline)
            }
            Text(.init("Your iPhone comes with a free app called **Shortcuts** - think of it as a tiny robot that does things for you. We'll teach it one job: *every morning, generate a fresh wallpaper and save it to your Photos*. Setup takes about 2 minutes. You only do it once."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(.init("On iOS 26, **Apple removed the action that lets apps change your wallpaper automatically**. The good news: your iPhone will still save the fresh wallpaper to Photos every morning and send you a notification - one tap to apply it."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Text("Labels in the steps below may differ slightly on your iOS version - look for the closest match.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Recommended recipe (always expanded)

    private var recommendedRecipe: some View {
        let recipe = Self.recipes[0] // "morning"
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.indigo)
                Text("RECOMMENDED")
                    .font(.caption2.bold())
                    .foregroundStyle(.indigo)
                    .tracking(0.5)
            }
            .padding(.bottom, 8)

            recipeCard(recipe, prominent: true)
        }
    }

    // MARK: - More recipes

    private var moreRecipesDisclosure: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showMoreRecipes.toggle()
                }
            } label: {
                HStack {
                    Text("Other ideas")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: showMoreRecipes ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showMoreRecipes {
                VStack(spacing: 10) {
                    ForEach(Self.recipes.dropFirst(), id: \.id) { recipe in
                        recipeCard(recipe, prominent: false)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func recipeCard(_ recipe: AutomationRecipe, prominent: Bool) -> some View {
        let isExpanded = prominent || expandedRecipeID == recipe.id
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                if prominent { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedRecipeID = expandedRecipeID == recipe.id ? nil : recipe.id
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: recipe.icon)
                        .font(.title3)
                        .foregroundStyle(.indigo)
                        .frame(width: 32, height: 32)
                        .background(Color.indigo.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipe.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text(recipe.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    if !prominent {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
            }
            .buttonStyle(.plain)
            .disabled(prominent)

            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider()

                    Text("Step by step")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .tracking(0.5)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { idx, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(idx + 1)")
                                    .font(.footnote.bold())
                                    .foregroundStyle(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Color.indigo)
                                    .clipShape(Circle())
                                Text(.init(step))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // Verify block
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Did it work?")
                                .font(.caption.bold())
                            Text(.init(recipe.verify))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button {
                        openShortcuts()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.forward.app")
                                .font(.subheadline.bold())
                            Text("Open Shortcuts and follow along")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.indigo)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(prominent ? Color.indigo.opacity(0.35) : .clear, lineWidth: 1.5)
        )
    }

    // MARK: - Custom Setup (collapsed)

    @State private var showCustom = false

    private var customSetupDisclosure: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCustom.toggle()
                }
            } label: {
                HStack {
                    Text("Build your own")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: showCustom ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if showCustom {
                VStack(alignment: .leading, spacing: 12) {
                    stepRow(number: 1, text: "Open the **Shortcuts** app and tap the **Automation** tab.")
                    stepRow(number: 2, text: "Create a new automation with any trigger (Time of Day, Focus mode, Location, Alarm, Sunset, etc.).")
                    stepRow(number: 3, text: "Add action: **\"Generate Today's Wallpaper\"** or **\"Generate Wallpaper\"** (search by name).")
                    stepRow(number: 4, text: "Set **Automation: Run Immediately** so it triggers silently. Leave **Notify When Run** off.")
                    stepRow(number: 5, text: "Tap **Done**. When the automation runs, the wallpaper lands in your Photos with a notification - tap to apply.")
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func stepRow(number: Int, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.indigo)
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Tips

    private var tips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("If something doesn't work")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            tipRow(icon: "bell.badge", text: "Didn't get a notification? Make sure Lock Screen Studio has notification permission enabled in your iPhone's Settings app → Notifications → Lock Screen Studio.")
            tipRow(icon: "play.circle", text: "Test now without waiting: Shortcuts → Automation → tap your automation → tap the ▶ triangle.")
            tipRow(icon: "photo.on.rectangle", text: "Don't see the new wallpaper in Photos? Make sure the app has permission: Settings → Privacy & Security → Photos → Lock Screen Studio → Add Only or Full Access.")
            tipRow(icon: "exclamationmark.circle", text: "Why the manual final tap? Apple removed the \"Set Wallpaper\" Shortcuts action in iOS 26. The fastest workflow now is automation → notification → tap once to apply.")
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.indigo)
                .frame(width: 20)
            Text(.init(text))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Open Shortcuts

    private var openShortcutsButton: some View {
        Button {
            openShortcuts()
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

    private func openShortcuts() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Recipes

    struct AutomationRecipe: Identifiable {
        let id: String
        let icon: String
        let title: String
        let summary: String
        let steps: [String]
        /// One-line description of what the user should observe to confirm it worked.
        let verify: String
    }

    /// Shared "what happens when it runs" block reused by every recipe to keep
    /// the iOS-26 manual-apply flow explained consistently in one place.
    private static let manualApplyVerify =
        "When the automation runs, your iPhone generates a fresh wallpaper, saves it to Photos, and shows you a notification \"Wallpaper Updated\". Tap the notification → Photos opens → tap **Share** → **Use as Wallpaper** → **Lock Screen**. One tap to apply, no need to open this app."

    static let recipes: [AutomationRecipe] = [
        AutomationRecipe(
            id: "morning",
            icon: "sunrise.fill",
            title: "Daily morning refresh",
            summary: "A fresh wallpaper waiting in Photos every morning - one tap to apply.",
            steps: [
                "On your iPhone, swipe down from the middle of the Home Screen to open **Search**. Type **Shortcuts** and tap the app (purple/blue square with two swirls).",
                "At the bottom you'll see two tabs. Tap **Automation**.",
                "If it's your first time, tap the big **New Automation** button in the middle of the screen. If you already have automations, tap **+** in the top right.",
                "Scroll the long list until you see **Time of Day** and tap it.",
                "Set the time (try **7:00 AM**). Under \"Repeat\" make sure **Daily** is selected. Tap **Next** in the top right.",
                "You'll see a search bar. Type **Generate Today's Wallpaper** and tap the result that appears under the **Lock Screen Studio** heading (that's this app).",
                "Tap **Next** (top right). On the review screen, **set Automation to \"Run Immediately\"** and leave **\"Notify When Run\"** off. Tap **Done**.",
            ],
            verify: manualApplyVerify
        ),
        AutomationRecipe(
            id: "alarm",
            icon: "alarm.fill",
            title: "Refresh when your alarm goes off",
            summary: "Stop your alarm, find a fresh wallpaper waiting in Photos.",
            steps: [
                "Open the **Shortcuts** app and tap the **Automation** tab.",
                "Tap **New Automation** (first time) or **+** (top right) and pick **Alarm**.",
                "Choose **Is Stopped** and tap **Next**.",
                "Search **Generate Today's Wallpaper** and tap it.",
                "Tap **Next**. Set Automation to **Run Immediately**, leave **Notify When Run** off, tap **Done**.",
            ],
            verify: manualApplyVerify
        ),
        AutomationRecipe(
            id: "focus",
            icon: "moon.zzz.fill",
            title: "Switch wallpaper with Focus mode",
            summary: "Turn on Work Focus and get a dark-themed wallpaper saved to Photos.",
            steps: [
                "Open the **Shortcuts** app and tap the **Automation** tab.",
                "Tap **New Automation** or **+**, then pick **Focus**.",
                "Tap the Focus you want (e.g. **Work**), choose **Is Turned On**, then **Next**.",
                "Search **Generate Wallpaper** and tap it. In the action, pick your work template and choose Dark theme.",
                "Tap **Next**. Set Automation to **Run Immediately**, leave **Notify When Run** off, tap **Done**.",
                "To also get a light version when Focus turns off: repeat from step 2, but choose **Is Turned Off** and a Light theme.",
            ],
            verify: manualApplyVerify
        ),
        AutomationRecipe(
            id: "location",
            icon: "location.fill",
            title: "Refresh when arriving at work",
            summary: "Walk into the office and find a Meeting Day wallpaper ready in Photos.",
            steps: [
                "Open the **Shortcuts** app and tap the **Automation** tab.",
                "Tap **New Automation** or **+**, then pick **Arrive**.",
                "Tap **Location**, search for your work address, select it, then tap **Done** and **Next**.",
                "Search **Generate Wallpaper** and tap it. Pick the **Meeting Day** template.",
                "Tap **Next**. Set Automation to **Run Immediately**, leave **Notify When Run** off, tap **Done**.",
            ],
            verify: manualApplyVerify
        ),
        AutomationRecipe(
            id: "sunset",
            icon: "sun.haze.fill",
            title: "Dark wallpaper at sunset",
            summary: "Saves a dark-themed wallpaper to Photos when the sun sets.",
            steps: [
                "Open the **Shortcuts** app and tap the **Automation** tab.",
                "Tap **New Automation** or **+**, then pick **Sunset**. Tap **Next**.",
                "Search **Generate Wallpaper** and tap it. Pick a template and Dark theme.",
                "Tap **Next**. Set Automation to **Run Immediately**, leave **Notify When Run** off, tap **Done**.",
                "To also get a light version at sunrise: repeat from step 2 with **Sunrise** and a Light theme.",
            ],
            verify: manualApplyVerify
        ),
    ]
}

// MARK: - Legacy aliases (kept so existing call sites keep working)

struct ShortcutsGuideView: View {
    var body: some View { ShortcutsSetupSheet() }
}

struct ShortcutsWizardSheet: View {
    var body: some View { ShortcutsSetupSheet() }
}

#Preview("Setup") {
    ShortcutsSetupSheet()
}
