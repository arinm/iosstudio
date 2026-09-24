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
                    // Suppressed once a ready-made link exists: the link does
                    // the same job deterministically, and describing it out
                    // loud is the path that most often produces a shortcut
                    // that only opens the app. Two "start here" cards compete;
                    // the reliable one wins.
                    if Self.usesInlineAutomations && !offersReadyMadeShortcuts {
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

            Text(.init(offersReadyMadeShortcuts
                ? "Teach the free **Shortcuts** app one job: build a fresh wallpaper every morning and put it straight on your Lock Screen. Pick a recipe below, add it, and switch it on - under a minute."
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
                Text("WORTH A TRY FIRST")
                    .font(.caption2.bold())
                    .foregroundStyle(.indigo)
                    .tracking(0.5)
            }

            Text(.init("Your iPhone can try to build this for you. In **Shortcuts**, tap **New Shortcut** and describe what you want:"))
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

            Text(.init("Say it in English - the actions are named in English, so that is what it matches on. Needs Apple Intelligence.\n\n**Check what it built.** It often gets the timing right but misses the work: if the shortcut just says \u{201C}Opens Lock Screen Studio\u{201D}, it skipped the two actions that matter. Build it by hand with the steps below instead - that takes two minutes and always works."))
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
                let shareLink = readyMadeLink(for: recipe.id)
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
                        // The old "names can differ, pick the closest match"
                        // hedge is gone: the steps now branch by iOS version
                        // and every name in them was read off the real screen,
                        // so telling people to approximate reads as a lack of
                        // confidence we no longer have.
                        Text(Self.usesInlineAutomations ? "Written for iOS 27." : "Written for iOS 26.")
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

    /// Primary path once a ready-made shortcut has been published: an import
    /// instead of a seven-step walkthrough.
    ///
    /// Deliberately not sold as "one tap". iOS installs a shared automation
    /// switched **off**, by design, so a user who stops after "Add Shortcut"
    /// owns a shortcut that never runs and gets no error explaining why. That
    /// makes enabling it a numbered step with its own heading, for the same
    /// reason `Show Preview` inside `Set Wallpaper Photo` became one: the step that
    /// fails silently is the step that has to be impossible to skim past.
    private func addToShortcutsButton(_ link: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(Self.importSteps.enumerated()), id: \.offset) { idx, step in
                    stepRow(number: idx + 1, text: .init(step))
                }
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                // "That second step", not "step 2": the walkthrough below has
                // its own numbered list on the same card.
                Text(.init("Skip that second step and nothing happens tomorrow morning - and nothing tells you why. It is the only part of this worth double-checking."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(.init("The schedule, both actions and the settings inside them all come with it - including the one that would otherwise ask you to confirm the change every single morning."))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// What happens after the link opens. Two steps, because that is genuinely
    /// all there is — and because a list of two makes the second one unmissable.
    static let importSteps: [String] = [
        "Shortcuts opens with everything already filled in. Tap **Add Shortcut**.",
        // Names the control seen on screen — the **Automation** toggle inside
        // the expanded trigger block — rather than the "Automation is turned
        // off" string from WorkflowEditor's table, which we never saw rendered.
        // A name in the binary is not proof of a name on the screen.
        "**Now check it is on.** Open the shortcut, tap the **chevron** on its trigger, and make sure **Automation** is switched on. A shared automation can arrive switched off - that is iOS protecting you from installing something that runs by itself, not a bug.",
    ]

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
                        text: "Add the system **Set Wallpaper Photo** action right below it, targeting **Lock Screen**, and turn its **Show Preview** option off."
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
            tipRow(icon: "hand.tap", text: "Asked to confirm every morning? That is **Show Preview**, inside **Set Wallpaper Photo**. Turn it off and it applies silently.")
            tipRow(icon: "magnifyingglass", text: "Can't find the action? It is called **Set Wallpaper Photo**, not \"Set Wallpaper\" - searching for either finds it, but the row you want is the one with the Shortcuts icon, not one of ours.")
            tipRow(icon: "photo.badge.checkmark", text: "Wallpaper didn't change at all? Check that **Set Wallpaper Photo** sits directly below the Generate step and is set to **Lock Screen**. If its image slot looks empty, tap it and pick the variable from the step above.")
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
        /// The trigger and its options on iOS 26 and earlier — the only part
        /// that differs between recipes.
        let trigger: [String]
        /// Replaces `trigger` on iOS 27+, where it differs.
        ///
        /// Most triggers are picked the same way on both, so this is usually
        /// nil. It exists because two are genuinely different there: Sunset
        /// stopped being a trigger of its own and became an **Event** option
        /// inside Time of Day, and Focus became a heading over the individual
        /// modes rather than a row you pick and then narrow.
        var inlineTrigger: [String]? = nil
        /// What the shortcut does once triggered.
        let actions: [String]
        /// One-line description of what the user should observe to confirm it worked.
        let verify: String

        /// Composed at read time. The taps that name Apple's own UI live in
        /// `openingSteps`/`finishingSteps` so an iOS redesign is one edit, not
        /// five — iOS 27 moving automations out of their own tab broke every
        /// recipe at once when these were copy-pasted per recipe.
        var steps: [String] {
            ShortcutsSetupSheet.steps(
                trigger: trigger,
                inlineTrigger: inlineTrigger,
                actions: actions,
                inlineAutomations: ShortcutsSetupSheet.usesInlineAutomations
            )
        }
    }

    /// Split from `AutomationRecipe.steps` so tests can compose both versions'
    /// copy rather than only the simulator's — see `openingSteps(inlineAutomations:)`.
    static func steps(
        trigger: [String],
        inlineTrigger: [String]?,
        actions: [String],
        inlineAutomations: Bool
    ) -> [String] {
        openingSteps(inlineAutomations: inlineAutomations)
            + (inlineAutomations ? (inlineTrigger ?? trigger) : trigger)
            + actions
            + finishingSteps(inlineAutomations: inlineAutomations)
    }

    /// True on the iOS versions where automations live inside a shortcut rather
    /// than in their own tab.
    static var usesInlineAutomations: Bool {
        if #available(iOS 27.0, *) { return true }
        return false
    }

    /// A ready-made link, but only where importing one actually delivers a
    /// working automation.
    ///
    /// These shortcuts carry their trigger as an action inside the shortcut,
    /// which is an iOS 27 concept. What iOS 26 does with such a file is not
    /// something we can promise — it may strip the trigger and leave a shortcut
    /// that looks installed but never fires, which is a worse outcome than a
    /// walkthrough. So older versions get the walkthrough, which is known to
    /// work, and the offer simply doesn't appear.
    private func readyMadeLink(for recipeID: String) -> URL? {
        guard Self.usesInlineAutomations else { return nil }
        return ShortcutLibrary.shareLink(for: recipeID)
    }

    /// Whether the guide can lead with importing rather than building.
    private var offersReadyMadeShortcuts: Bool {
        Self.usesInlineAutomations && ShortcutLibrary.hasAnyShareLink
    }

    /// Getting to the trigger picker. Differs by iOS version.
    static var openingSteps: [String] { openingSteps(inlineAutomations: usesInlineAutomations) }

    /// Split out from the property so tests can read both branches. Behind
    /// `#available` only the running OS's copy is reachable, which means the
    /// other half of this screen — the half most of our installed base sees —
    /// would go unchecked on a simulator.
    static func openingSteps(inlineAutomations: Bool) -> [String] {
        guard inlineAutomations else {
            return [
                "Open the **Shortcuts** app.",
                "Tap the **Automation** tab at the bottom, then **New Automation** (or **+** in the top right if you already have some).",
            ]
        }
        return [
            "Open the **Shortcuts** app.",
            "Tap **New Shortcut**. It opens a \u{201C}Describe a Shortcut\u{201D} text box first - tap **Edit** in the top right for the manual editor. Tired of doing that every time? **Settings → Apps → Shortcuts → Open shortcuts to → Editor** makes the editor the default.",
            "In the action list along the bottom, tap **Automation**. That filters the list down to triggers, grouped under **Daily Routine**, **Location** and so on.",
        ]
    }

    /// Saving the automation once the actions are in place.
    static var finishingSteps: [String] { finishingSteps(inlineAutomations: usesInlineAutomations) }

    /// On iOS 27 these two controls live inside the trigger block and are
    /// labelled **Automation** and **Notify**. The older **Run Immediately** /
    /// **Notify When Run** wording still exists in Apple's string table on
    /// iOS 27 — which is why a string-table match alone is not proof — but the
    /// inline trigger does not use it.
    static func finishingSteps(inlineAutomations: Bool) -> [String] {
        guard inlineAutomations else {
            return [
                "Set it to **Run Immediately**, then save. The default is **Run After Confirmation**, which would ask you to approve it every single morning.",
            ]
        }
        return [
            "Tap the **chevron** on the trigger to open its settings. Leave **Automation** on and **Notify** off - that second one is what stops it announcing itself every morning.",
            "Tap **Back**. There is no save button; changes apply as you make them.",
        ]
    }

    /// Shared by every recipe: generate, then apply. Only the template and theme
    /// differ, so those recipes pass their own version of the first line.
    ///
    /// The action is **Set Wallpaper Photo** and the toggle is **Show Preview**.
    /// Both names are read from Apple's own `ActionKit` string table (keys
    /// `Set Wallpaper Photo (Action Name)` and `WFWallpaperShowPreview`) and are
    /// identical on iOS 26.1, 26.2 and 27, so there is nothing to branch on. The
    /// guide previously said "Set Wallpaper", which does not exist under that
    /// name — searching for it lands people on the right row only because the
    /// real one starts with the same two words.
    static func applyActions(generate: String) -> [String] {
        [
            generate,
            "Add **Set Wallpaper Photo** right below it, targeting **Lock Screen**. It picks up the image from the step above automatically.",
            "**Don\u{2019}t skip this one.** Open that action\u{2019}s options and turn **Show Preview** off. Left on, iOS shows a \u{201C}change your wallpaper?\u{201D} sheet you have to tap every single morning - which is the one thing this whole setup exists to avoid.",
        ]
    }

    /// Shared "what happens when it runs" block reused by every recipe so the
    /// hands-off flow is explained consistently in one place.
    ///
    /// Written as concatenated single lines rather than a `"""` block: the
    /// block form here had its newlines collapsed into the leading indentation
    /// at some point, leaving runs of spaces that shipped as visible gaps in
    /// the middle of sentences. `ShortcutsCopyTests` now guards against that.
    private static let autoApplyVerify =
        "Lock your iPhone and look - the new wallpaper is already there. "
        + "Don't want to wait for the trigger? Open the shortcut and tap the "
        + "▶ triangle to run it now.\n\n"
        + "If it asks you to confirm the change instead of just doing it, "
        + "**Show Preview** inside **Set Wallpaper Photo** is still on - go "
        + "back and turn it off."

    static let recipes: [AutomationRecipe] = [
        AutomationRecipe(
            id: "morning",
            icon: "sunrise.fill",
            title: "Daily morning refresh",
            summary: "Wake up to a Lock Screen that already shows today.",
            trigger: [
                "Pick **Time of Day**.",
                "Set a time like **7:00 AM** and, under **Repeat**, make sure **Daily** is selected.",
            ],
            inlineTrigger: [
                "Pick **Time of Day**, under **Daily Routine**.",
                "Tap the blue **Time** and set it to something like **7:00 AM**.",
                "Tap the **chevron** beside it to check **Repeat** says **Every Day**.",
            ],
            actions: applyActions(
                generate: "Add the action **Generate Today's Wallpaper** - search for it and pick the row with the Lock Screen Studio icon."
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
                "There is no single Focus trigger - scroll to the Focus group and pick the mode you want, such as **Do Not Disturb**.",
                "Choose **Is Turned On**.",
            ],
            inlineTrigger: [
                "Scroll to the **Focus** heading and pick the mode you want - **Do Not Disturb**, or one you have set up yourself.",
                "Tap the **chevron** on the trigger and set it to run when that Focus **is turned on**.",
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
                "Location automations need one system permission or they silently never run: **Settings → Privacy & Security → Location Services → System Services → Alerts & Shortcuts Automations**.",
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
                "There is no Sunset trigger of its own - pick **Time of Day**.",
                "On the **When** screen, choose **Sunset** from the three options at the top.",
            ],
            inlineTrigger: [
                "There is no Sunset trigger of its own here - pick **Time of Day**.",
                "Tap the **chevron** on it, then change **Event** from **Time of Day** to **Sunset**.",
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
