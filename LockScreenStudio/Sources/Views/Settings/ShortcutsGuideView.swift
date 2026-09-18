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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.indigo)
                    .symbolEffect(.pulse, options: .repeat(2))
                Text("Wake up to a fresh wallpaper")
                    .font(.headline)
            }

            Text(.init(ShortcutLibrary.hasAnyShareLink
                ? "Teach the free **Shortcuts** app one job: build a fresh wallpaper every morning and put it straight on your Lock Screen. Pick a recipe below and add it in one tap."
                : "Teach the free **Shortcuts** app one job: build a fresh wallpaper every morning and put it straight on your Lock Screen. Set it up once, about 2 minutes."))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            howItWorksStrip

            Text(.init("**Lock Screen Studio can't change your wallpaper by itself** - iOS doesn't allow that. The Shortcuts app can, so your automation does it for you."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Visual 3-stage flow so the user sees at a glance what is automatic and
    /// what the single manual tap is — instead of reading two paragraphs.
    private var howItWorksStrip: some View {
        HStack(spacing: 4) {
            howItWorksStage(icon: "clock.badge.checkmark", label: "Trigger\nfires", automatic: true)
            stageArrow
            howItWorksStage(icon: "arrow.triangle.2.circlepath", label: "Wallpaper\nbuilt", automatic: true)
            stageArrow
            howItWorksStage(icon: "lock.iphone", label: "Lock Screen\nupdated", automatic: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.indigo.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func howItWorksStage(icon: String, label: String, automatic: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(automatic ? Color.indigo : Color.orange)
                .frame(height: 24)
            Text(label)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
            Text(automatic ? "automatic" : "you")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(automatic ? Color.indigo : Color.orange)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var stageArrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption2.bold())
            .foregroundStyle(.tertiary)
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
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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
                let shareLink = ShortcutLibrary.shareLink(for: recipe.id)
                VStack(alignment: .leading, spacing: 14) {
                    Divider()

                    if let shareLink {
                        addToShortcutsButton(shareLink)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(shareLink == nil ? "Step by step" : "Or build it yourself")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                        Text("Button names can differ slightly between iOS versions - pick the closest match.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

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

    /// Primary path once a ready-made shortcut has been published: one tap to
    /// import, instead of a seven-step walkthrough.
    private func addToShortcutsButton(_ link: URL) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                UIApplication.shared.open(link)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.subheadline.bold())
                    Text("Add to Shortcuts")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.indigo)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Text(.init("Shortcuts opens with everything filled in. Tap **Add Shortcut**, then switch the automation on - iOS deliberately ships shared automations turned off."))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Custom Setup (collapsed)

    @State private var showCustom = false

    private var customSetupDisclosure: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
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
                    stepRow(number: 4, text: "Add the system **\"Set Wallpaper\"** action right below it, targeting **Lock Screen**. It consumes the image step 3 produced.")
                    stepRow(number: 5, text: "Set **Automation: Run Immediately** so it triggers silently. Leave **Notify When Run** off.")
                    stepRow(number: 6, text: "Tap **Done**. From now on your Lock Screen updates itself on that trigger.")
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
            tipRow(icon: "photo.on.rectangle", text: "Want a copy in Photos too? Automations don't save one by default. Turn on **Also save to Photos** in Settings → Automation, and allow Photos access when asked.")
            tipRow(icon: "photo.badge.checkmark", text: "Wallpaper didn't change? Check that **Set Wallpaper** sits directly below the Generate step and is set to **Lock Screen**. If its image slot looks empty, tap it and pick the variable from the step above.")
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

    /// Shared "what happens when it runs" block reused by every recipe so the
    /// hands-off flow is explained consistently in one place.
    private static let autoApplyVerify =
        "Lock your iPhone and look - the new wallpaper is already there. Don't want to wait for the trigger? Shortcuts → your automation → tap the ▶ triangle to run it now."

    static let recipes: [AutomationRecipe] = [
        AutomationRecipe(
            id: "morning",
            icon: "sunrise.fill",
            title: "Daily morning refresh",
            summary: "A fresh wallpaper waiting in Photos every morning, ready to apply.",
            steps: [
                "Swipe down on your Home Screen to open **Search**, type **Shortcuts**, and open the app (purple/blue square with two swirls).",
                "Tap the **Automation** tab at the bottom.",
                "Tap **New Automation** (or **+** in the top right if you already have some).",
                "Pick **Time of Day** from the list.",
                "Set a time like **7:00 AM**, make sure **Daily** is selected, then tap **Next**.",
                "In the search bar, type **Generate Today's Wallpaper** and tap the result under **Lock Screen Studio** (that's this app).",
                "Tap **+** underneath, search **Set Wallpaper**, and add it. Make sure it targets **Lock Screen** - it picks up the image from the step above automatically.",
                "Tap **Next**, set Automation to **Run Immediately**, leave **Notify When Run** off, and tap **Done**.",
            ],
            verify: autoApplyVerify
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
                "Search **Set Wallpaper** and add it below. Confirm it targets **Lock Screen**.",
                "Tap **Next**. Set Automation to **Run Immediately**, leave **Notify When Run** off, tap **Done**.",
            ],
            verify: autoApplyVerify
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
                "Search **Set Wallpaper** and add it below, targeting **Lock Screen**.",
                "Tap **Next**. Set Automation to **Run Immediately**, leave **Notify When Run** off, tap **Done**.",
                "To also get a light version when Focus turns off: repeat from step 2, but choose **Is Turned Off** and a Light theme.",
            ],
            verify: autoApplyVerify
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
                "Search **Set Wallpaper** and add it below, targeting **Lock Screen**.",
                "Tap **Next**. Set Automation to **Run Immediately**, leave **Notify When Run** off, tap **Done**.",
            ],
            verify: autoApplyVerify
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
                "Search **Set Wallpaper** and add it below, targeting **Lock Screen**.",
                "Tap **Next**. Set Automation to **Run Immediately**, leave **Notify When Run** off, tap **Done**.",
                "To also get a light version at sunrise: repeat from step 2 with **Sunrise** and a Light theme.",
            ],
            verify: autoApplyVerify
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
