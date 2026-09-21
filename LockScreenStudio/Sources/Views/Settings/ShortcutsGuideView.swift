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
                    if Self.usesInlineAutomations {
                        describeShortcutCard
                    }
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

    /// Visual 3-stage flow so the user sees at a glance that nothing is left
    /// for them to do — instead of reading two paragraphs.
    private var howItWorksStrip: some View {
        HStack(spacing: 4) {
            howItWorksStage(icon: "clock.badge.checkmark", label: "Trigger\nfires")
            stageArrow
            howItWorksStage(icon: "arrow.triangle.2.circlepath", label: "Wallpaper\nbuilt")
            stageArrow
            howItWorksStage(icon: "lock.iphone", label: "Lock Screen\nupdated")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.indigo.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Every stage is automatic now. The old orange "you" variant is gone
    /// rather than left unused — an unused branch reads as "a manual step is
    /// still possible here", which is exactly the impression this strip exists
    /// to remove.
    private func howItWorksStage(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.indigo)
                .frame(height: 24)
            Text(label)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
            Text("automatic")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.indigo)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var stageArrow: some View {
        Image(systemName: "chevron.right")
            .font(.caption2.bold())
            .foregroundStyle(.tertiary)
    }

    // MARK: - Describe a Shortcut (iOS 27+)

    /// On iOS 27 the whole walkthrough below collapses into one sentence the
    /// user dictates. Shown above the recipes because it is genuinely the
    /// shortest path — the manual steps stay for anyone whose device has no
    /// Apple Intelligence, or who prefers building it by hand.
    private var describeShortcutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(.indigo)
                Text("FASTEST WAY")
                    .font(.caption2.bold())
                    .foregroundStyle(.indigo)
                    .tracking(0.5)
            }

            Text(.init("Your iPhone can build this for you. In **Shortcuts**, tap **New Shortcut** and describe what you want:"))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            Text("\u{201C}Every morning at 7, generate today\u{2019}s wallpaper with Lock Screen Studio and set it as my lock screen.\u{201D}")
                .font(.subheadline.italic())
                .foregroundStyle(.indigo)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.indigo.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .fixedSize(horizontal: false, vertical: true)

            Text(.init("Say it in English - the actions are named in English, so that is what it matches on. Needs Apple Intelligence; if your iPhone doesn\u{2019}t have it, use the steps below instead."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
                    ForEach(Array(Self.openingSteps.enumerated()), id: \.offset) { idx, step in
                        stepRow(number: idx + 1, text: .init(step))
                    }
                    stepRow(
                        number: Self.openingSteps.count + 1,
                        text: "Pick any trigger you like - Time of Day, Focus, Arrive, Alarm, Sunset."
                    )
                    stepRow(
                        number: Self.openingSteps.count + 2,
                        text: "Add **\"Generate Today's Wallpaper\"** or **\"Generate Wallpaper\"**, searching by name."
                    )
                    stepRow(
                        number: Self.openingSteps.count + 3,
                        text: "Add the system **\"Set Wallpaper\"** action right below it, targeting **Lock Screen**. If it offers a **Show Preview** option, turn that off."
                    )
                    ForEach(Array(Self.finishingSteps.enumerated()), id: \.offset) { idx, step in
                        stepRow(number: Self.openingSteps.count + 4 + idx, text: .init(step))
                    }
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
            tipRow(icon: "play.circle", text: "Test now without waiting: open the shortcut in the **Shortcuts** app and tap the ▶ triangle. No need to wait for the trigger.")
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
        /// The trigger and its options — the only part that differs between
        /// recipes.
        let trigger: [String]
        /// What the shortcut does once triggered.
        let actions: [String]
        /// One-line description of what the user should observe to confirm it worked.
        let verify: String

        /// Composed at read time. The taps that name Apple's own UI live in
        /// `openingSteps`/`finishingSteps` so an iOS redesign is one edit, not
        /// five — iOS 27 moving automations out of their own tab broke every
        /// recipe at once when these were copy-pasted per recipe.
        var steps: [String] {
            ShortcutsSetupSheet.openingSteps
                + trigger
                + actions
                + ShortcutsSetupSheet.finishingSteps
        }
    }

    /// True on the iOS versions where automations live inside a shortcut rather
    /// than in their own tab.
    static var usesInlineAutomations: Bool {
        if #available(iOS 27.0, *) { return true }
        return false
    }

    /// Getting to the trigger picker. Differs by iOS version.
    static var openingSteps: [String] {
        if usesInlineAutomations {
            return [
                "Open the **Shortcuts** app.",
                "Tap **New Shortcut**. It opens a \"Describe a Shortcut\" text box first - tap the **three-line icon** to switch to the manual editor.",
                "Tap **Edit**, then **Automation**.",
            ]
        }
        return [
            "Open the **Shortcuts** app.",
            "Tap the **Automation** tab at the bottom, then **New Automation** (or **+** in the top right if you already have some).",
        ]
    }

    /// Saving the automation once the actions are in place.
    static var finishingSteps: [String] {
        [
            "Set it to **Run Immediately** and leave **Notify When Run** off, then save.",
        ]
    }

    /// Shared by every recipe: generate, then apply. Only the template and theme
    /// differ, so those recipes pass their own version of the first line.
    static func applyActions(generate: String) -> [String] {
        [
            generate,
            "Add **Set Wallpaper** right below it, targeting **Lock Screen**. It picks up the image from the step above automatically. If it offers a **Show Preview** option, turn that off so it applies without asking you first.",
        ]
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
            summary: "Wake up to a Lock Screen that already shows today.",
            trigger: [
                "Pick **Time of Day**.",
                "Set a time like **7:00 AM** and make sure **Daily** is selected.",
            ],
            actions: applyActions(
                generate: "Add the action **Generate Today's Wallpaper** - search for it, it is listed under **Lock Screen Studio** (this app)."
            ),
            verify: autoApplyVerify
        ),
        AutomationRecipe(
            id: "alarm",
            icon: "alarm.fill",
            title: "Refresh when your alarm goes off",
            summary: "Stop your alarm, unlock to a fresh Lock Screen.",
            trigger: [
                "Pick **Alarm**, then choose **Is Stopped**.",
            ],
            actions: applyActions(
                generate: "Add the action **Generate Today's Wallpaper**."
            ),
            verify: autoApplyVerify
        ),
        AutomationRecipe(
            id: "focus",
            icon: "moon.zzz.fill",
            title: "Switch wallpaper with Focus mode",
            summary: "Work Focus on, work wallpaper on.",
            trigger: [
                "Pick **Focus**, tap the one you want (e.g. **Work**), and choose **Is Turned On**.",
            ],
            actions: applyActions(
                generate: "Add the action **Generate Wallpaper**, then pick your work template and the **Dark** theme."
            ) + [
                "Want a light version when Focus ends? Build a second one the same way, choosing **Is Turned Off** and a Light theme.",
            ],
            verify: autoApplyVerify
        ),
        AutomationRecipe(
            id: "location",
            icon: "location.fill",
            title: "Refresh when arriving at work",
            summary: "Walk in, and your Lock Screen is already on meetings.",
            trigger: [
                "Pick **Arrive**, tap **Location**, search for your work address and select it.",
            ],
            actions: applyActions(
                generate: "Add the action **Generate Wallpaper** and pick the **Meeting Day** template."
            ),
            verify: autoApplyVerify
        ),
        AutomationRecipe(
            id: "sunset",
            icon: "sun.haze.fill",
            title: "Dark wallpaper at sunset",
            summary: "The Lock Screen dims when the day does.",
            trigger: [
                "Pick **Sunset**.",
            ],
            actions: applyActions(
                generate: "Add the action **Generate Wallpaper**, then pick a template and the **Dark** theme."
            ) + [
                "Want it to brighten again in the morning? Build a second one with **Sunrise** and a Light theme.",
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
