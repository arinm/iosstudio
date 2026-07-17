import SwiftUI
import SwiftData

struct TemplateGalleryView: View {
    @Query(sort: \WallpaperTemplate.sortOrder) private var templates: [WallpaperTemplate]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var templateImportCoordinator: TemplateImportCoordinator
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showHistory = false
    @State private var showTemplateImporter = false
    @State private var importAlertTitle = ""
    @State private var importAlertMessage = ""
    @State private var showImportAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                templateGrid
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Lock Screen Studio")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        showTemplateImporter = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Import Template")

                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("History")

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack { HistoryView() }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(source: "gallery")
        }
        .fileImporter(
            isPresented: $showTemplateImporter,
            allowedContentTypes: [.lockScreenStudioTemplate]
        ) { result in
            switch result {
            case .success(let url):
                importTemplate(from: url, source: "file_picker")
            case .failure(let error):
                if (error as? CocoaError)?.code == .userCancelled { return }
                presentImportFailure(error, source: "file_picker")
            }
        }
        .alert(importAlertTitle, isPresented: $showImportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importAlertMessage)
        }
        .onAppear {
            TemplateSeeder.seedIfNeeded(context: modelContext)
            importPendingTemplateIfNeeded()
        }
        .onChange(of: templateImportCoordinator.pendingURL) {
            importPendingTemplateIfNeeded()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image("AppIconSmall")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text("Your daily dashboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !subscriptionManager.isPro {
                proPromoBanner
            }
        }
    }

    private var proPromoBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(.indigo)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock All Templates")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("Get Pro for unlimited exports & automation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Template Grid

    @State private var newTemplate: WallpaperTemplate?

    private var templateGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
        ], spacing: 20) {
            // Create custom template button
            Button {
                if subscriptionManager.isPro {
                    createCustomTemplate()
                } else {
                    showPaywall = true
                }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.tertiarySystemBackground))
                            .frame(height: 200)

                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(.indigo)
                            Text("Create Your Own")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.indigo.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    )

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("Custom")
                                    .font(.subheadline.bold())
                                    .lineLimit(1)
                                if !subscriptionManager.isPro {
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.indigo)
                                        .clipShape(Capsule())
                                }
                            }
                            Text("Build from scratch")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            .buttonStyle(.plain)

            ForEach(templates) { template in
                if template.isPro && !subscriptionManager.isPro {
                    Button {
                        showPaywall = true
                    } label: {
                        TemplateCardView(
                            template: template,
                            isPro: subscriptionManager.isPro
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    NavigationLink {
                        EditorView(template: template)
                    } label: {
                        TemplateCardView(
                            template: template,
                            isPro: subscriptionManager.isPro
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationDestination(item: $newTemplate) { template in
            EditorView(template: template)
        }
    }

    private func createCustomTemplate() {
        let template = WallpaperTemplate(
            name: "My Template",
            description: "Custom template",
            layoutType: .singleColumn,
            isPro: false,
            isBuiltIn: false,
            sortOrder: (templates.last?.sortOrder ?? 0) + 1
        )
        // Start with just Date & Time panel
        let datePanel = PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil)
        template.panels = [datePanel]
        modelContext.insert(template)
        try? modelContext.save()
        AnalyticsService.shared.track(.customTemplateCreated)
        newTemplate = template
    }

    private func importPendingTemplateIfNeeded() {
        guard let url = templateImportCoordinator.consumePendingURL() else { return }
        importTemplate(from: url, source: "open_url")
    }

    private func importTemplate(from url: URL, source: String) {
        do {
            let nextSortOrder = (templates.map(\.sortOrder).max() ?? -1) + 1
            let template = try TemplateSharingService.importTemplate(
                from: url,
                sortOrder: nextSortOrder
            )
            template.name = uniqueTemplateName(for: template.name)
            modelContext.insert(template)
            do {
                try modelContext.save()
            } catch {
                // Cancel only this insertion. A rollback on the shared main
                // context could discard unrelated edits still open elsewhere.
                modelContext.delete(template)
                throw error
            }

            var properties = TemplateSharingService.analyticsProperties(for: template)
            properties["source"] = source
            AnalyticsService.shared.track(.templateImported, properties: properties)

            importAlertTitle = "Template Imported"
            importAlertMessage = "\(template.name) is ready in your gallery."
            showImportAlert = true
        } catch {
            presentImportFailure(error, source: source)
        }
    }

    private func uniqueTemplateName(for requestedName: String) -> String {
        let existingNames = Set(templates.map { $0.name.lowercased() })
        guard existingNames.contains(requestedName.lowercased()) else {
            return requestedName
        }

        let copyName = "\(requestedName) Copy"
        guard existingNames.contains(copyName.lowercased()) else {
            return copyName
        }

        var copyNumber = 2
        while existingNames.contains("\(copyName) \(copyNumber)".lowercased()) {
            copyNumber += 1
        }
        return "\(copyName) \(copyNumber)"
    }

    private func presentImportFailure(_ error: Error, source: String) {
        let sharingError = error as? TemplateSharingError
        AnalyticsService.shared.track(
            .templateImportFailed,
            properties: [
                "reason": sharingError?.analyticsReason ?? "file_picker_error",
                "source": source,
            ]
        )
        importAlertTitle = "Couldn't Import Template"
        importAlertMessage = sharingError?.localizedDescription
            ?? "The selected file couldn't be opened."
        showImportAlert = true
    }
}

// MARK: - Template Card

struct TemplateCardView: View {
    let template: WallpaperTemplate
    let isPro: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Preview area — skeleton layout simulating the wallpaper
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)))
                    .frame(height: 200)

                // Skeleton preview mimicking the rendered wallpaper
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(template.panels.sorted(by: { $0.sortOrder < $1.sortOrder }).filter(\.isVisible).prefix(4).enumerated()), id: \.element.id) { index, panel in
                        VStack(alignment: .leading, spacing: 3) {
                            // Panel title skeleton
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.15))
                                .frame(width: panelTitleWidth(panel), height: 6)

                            // Content lines skeleton
                            ForEach(0..<min(panel.panelType.skeletonLineCount, 3), id: \.self) { lineIdx in
                                HStack(spacing: 4) {
                                    if panel.panelType == .agenda {
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(Color.indigo.opacity(0.5))
                                            .frame(width: 20, height: 5)
                                    }
                                    if panel.panelType == .topThree {
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(Color.indigo.opacity(0.5))
                                            .frame(width: 8, height: 5)
                                    }
                                    if panel.panelType == .todo {
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(lineIdx == 0 ? Color.white.opacity(0.12) : Color.indigo.opacity(0.4))
                                            .frame(width: 6, height: 6)
                                    }
                                    if panel.panelType == .countdown && lineIdx == 0 {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.indigo.opacity(0.6))
                                            .frame(width: 20, height: 10)
                                    }
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color.white.opacity(lineIdx == 0 && panel.panelType == .todo ? 0.12 : 0.22))
                                        .frame(width: contentLineWidth(lineIdx), height: 5)
                                }
                            }
                        }

                        // Separator
                        if index < template.panels.filter(\.isVisible).count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 0.5)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Pro overlay
                if template.isPro && !isPro {
                    Color.black.opacity(0.4)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }

            // Label + Use button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(template.name)
                            .font(.subheadline.bold())
                            .lineLimit(1)

                        if template.isPro && !isPro {
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.indigo)
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(template.panels.filter(\.isVisible).count) panels")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Use")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.indigo)
                    .clipShape(Capsule())
            }
        }
        .accessibilityLabel("\(template.name) template, \(template.panels.count) panels\(template.isPro && !isPro ? ", Pro required" : "")")
    }

    private func panelTitleWidth(_ panel: PanelConfiguration) -> CGFloat {
        switch panel.panelType {
        case .dateTime: return 55
        case .agenda: return 40
        case .topThree: return 30
        case .todo: return 28
        case .quote: return 32
        case .countdown: return 50
        case .notes: return 32
        default: return 36
        }
    }

    private func contentLineWidth(_ index: Int) -> CGFloat {
        [60, 48, 38, 52][index % 4]
    }
}

#Preview {
    NavigationStack {
        TemplateGalleryView()
            .environmentObject(SubscriptionManager())
            .environmentObject(TemplateImportCoordinator())
    }
}
