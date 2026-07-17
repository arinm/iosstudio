import Combine
import Foundation
import UniformTypeIdentifiers

extension UTType {
    static let lockScreenStudioTemplate = UTType(
        exportedAs: "com.lockscreenstudio.template",
        conformingTo: .json
    )
}

enum TemplateSharingError: LocalizedError, Equatable {
    case fileTooLarge
    case invalidFile
    case unsupportedVersion
    case tooManyPanels
    case unsupportedPanel
    case invalidContent

    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "This template file is too large."
        case .invalidFile:
            return "This isn't a valid Lock Screen Studio template."
        case .unsupportedVersion:
            return "This template was created by an unsupported app version."
        case .tooManyPanels:
            return "This template contains too many panels."
        case .unsupportedPanel:
            return "This template contains a panel type that isn't supported."
        case .invalidContent:
            return "This template contains invalid settings."
        }
    }

    var analyticsReason: String {
        switch self {
        case .fileTooLarge: return "file_too_large"
        case .invalidFile: return "invalid_file"
        case .unsupportedVersion: return "unsupported_version"
        case .tooManyPanels: return "too_many_panels"
        case .unsupportedPanel: return "unsupported_panel"
        case .invalidContent: return "invalid_content"
        }
    }
}

struct TemplateSharePayload: Identifiable {
    let id = UUID()
    let fileURL: URL
}

@MainActor
final class TemplateImportCoordinator: ObservableObject {
    @Published private(set) var pendingURL: URL?

    func enqueue(_ url: URL) {
        pendingURL = url
    }

    func consumePendingURL() -> URL? {
        defer { pendingURL = nil }
        return pendingURL
    }
}

/// Versioned, privacy-conscious import/export for template layouts. Dynamic
/// app data (todos, priorities, calendars, reminder lists, and photos) is not
/// part of the document format.
enum TemplateSharingService {
    static let currentVersion = 1
    static let maxFileSize = 256 * 1024
    static let maxPanelCount = 12

    private static let documentKind = "lock_screen_studio_template"
    private static let maxTemplateNameLength = 80
    private static let maxDescriptionLength = 240
    private static let maxPanelTitleLength = 80
    private static let maxConfigSize = 32 * 1024

    static func makeSharePayload(for template: WallpaperTemplate) throws -> TemplateSharePayload {
        let data = try exportData(for: template)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LockScreenStudioSharedTemplates", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let fileName = sanitizedFileName(template.name)
        let url = directory
            .appendingPathComponent("\(fileName)-\(UUID().uuidString.prefix(8))")
            .appendingPathExtension("lockscreenstudio")
        try data.write(to: url, options: .atomic)
        return TemplateSharePayload(fileURL: url)
    }

    static func exportData(for template: WallpaperTemplate) throws -> Data {
        let sortedPanels = template.panels.sorted { $0.sortOrder < $1.sortOrder }
        guard sortedPanels.count <= maxPanelCount else {
            throw TemplateSharingError.tooManyPanels
        }

        let panels = try sortedPanels.enumerated().map { index, panel in
            guard panel.panelType.isAvailable else {
                throw TemplateSharingError.unsupportedPanel
            }

            let trimmedTitle = panel.title.trimmingCharacters(in: .whitespacesAndNewlines)

            return SharedPanel(
                panelType: panel.panelType,
                sortOrder: index,
                isVisible: panel.isVisible,
                title: clipped(
                    trimmedTitle.isEmpty ? panel.panelType.defaultTitle : trimmedTitle,
                    maxLength: maxPanelTitleLength
                ),
                showTitle: panel.isTitleShown,
                configData: try sanitizedConfigData(
                    panel.configData,
                    for: panel.panelType
                )
            )
        }

        let document = SharedTemplateDocument(
            kind: documentKind,
            version: currentVersion,
            name: clipped(template.name, maxLength: maxTemplateNameLength),
            templateDescription: clipped(
                template.templateDescription,
                maxLength: maxDescriptionLength
            ),
            layoutType: template.layoutType,
            requiresPro: template.isPro || panels.contains { $0.panelType.isPro },
            panels: panels
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(document)
        guard data.count <= maxFileSize else {
            throw TemplateSharingError.fileTooLarge
        }
        return data
    }

    static func importTemplate(
        from url: URL,
        sortOrder: Int
    ) throws -> WallpaperTemplate {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = values?.fileSize, fileSize > maxFileSize {
            throw TemplateSharingError.fileTooLarge
        }

        let data: Data
        do {
            let fileHandle = try FileHandle(forReadingFrom: url)
            defer { try? fileHandle.close() }
            data = try fileHandle.read(upToCount: maxFileSize + 1) ?? Data()
        } catch {
            throw TemplateSharingError.invalidFile
        }
        guard data.count <= maxFileSize else {
            throw TemplateSharingError.fileTooLarge
        }
        return try importTemplate(from: data, sortOrder: sortOrder)
    }

    static func importTemplate(
        from data: Data,
        sortOrder: Int
    ) throws -> WallpaperTemplate {
        guard data.count <= maxFileSize else {
            throw TemplateSharingError.fileTooLarge
        }

        let document: SharedTemplateDocument
        do {
            document = try JSONDecoder().decode(SharedTemplateDocument.self, from: data)
        } catch {
            throw TemplateSharingError.invalidFile
        }

        guard document.kind == documentKind else {
            throw TemplateSharingError.invalidFile
        }
        guard document.version == currentVersion else {
            throw TemplateSharingError.unsupportedVersion
        }
        guard !document.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              document.name.count <= maxTemplateNameLength,
              document.templateDescription.count <= maxDescriptionLength else {
            throw TemplateSharingError.invalidContent
        }
        guard document.panels.count <= maxPanelCount else {
            throw TemplateSharingError.tooManyPanels
        }

        let sortedPanels = document.panels.sorted { $0.sortOrder < $1.sortOrder }
        var importedPanels: [PanelConfiguration] = []
        importedPanels.reserveCapacity(sortedPanels.count)

        for (index, sharedPanel) in sortedPanels.enumerated() {
            guard sharedPanel.panelType.isAvailable else {
                throw TemplateSharingError.unsupportedPanel
            }
            guard !sharedPanel.title.isEmpty,
                  sharedPanel.title.count <= maxPanelTitleLength else {
                throw TemplateSharingError.invalidContent
            }

            let panel = PanelConfiguration(
                panelType: sharedPanel.panelType,
                sortOrder: index,
                isVisible: sharedPanel.isVisible,
                title: sharedPanel.title,
                configData: try sanitizedConfigData(
                    sharedPanel.configData,
                    for: sharedPanel.panelType
                )
            )
            panel.showTitle = sharedPanel.showTitle
            importedPanels.append(panel)
        }

        return WallpaperTemplate(
            builtInKey: nil,
            name: document.name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: document.templateDescription,
            layoutType: document.layoutType,
            isPro: document.requiresPro || importedPanels.contains { $0.panelType.isPro },
            isBuiltIn: false,
            sortOrder: sortOrder,
            panels: importedPanels
        )
    }

    static func analyticsProperties(for template: WallpaperTemplate) -> [String: String] {
        let panelCount: String
        switch template.panels.count {
        case 0: panelCount = "0"
        case 1...3: panelCount = "1_3"
        case 4...6: panelCount = "4_6"
        default: panelCount = "7_plus"
        }

        return [
            "template_type": template.builtInKey == nil ? "custom" : "built_in",
            "requires_pro": String(template.isPro),
            "panel_count": panelCount,
        ]
    }

    private static func sanitizedConfigData(
        _ data: Data?,
        for panelType: PanelType
    ) throws -> Data? {
        guard let data else { return nil }
        guard data.count <= maxConfigSize else {
            throw TemplateSharingError.invalidContent
        }

        do {
            switch panelType {
            case .agenda:
                var config = try JSONDecoder().decode(AgendaConfig.self, from: data)
                config.maxEvents = min(max(config.maxEvents, 1), 10)
                return try JSONEncoder().encode(config)
            case .topThree:
                // Current priorities are personal task data, not template structure.
                return try JSONEncoder().encode(TopThreeConfig())
            case .todo:
                var config = try JSONDecoder().decode(TodoConfig.self, from: data)
                config.maxItems = min(max(config.maxItems, 1), 10)
                config.source = .local
                config.reminderListIdentifier = nil
                return try JSONEncoder().encode(config)
            case .dateTime:
                let config = try JSONDecoder().decode(DateTimeConfig.self, from: data)
                return try JSONEncoder().encode(config)
            case .habitsHeatmap:
                // Shareable since v1.13: the config carries only layout prefs.
                // Reset habitName (legacy field that may hold personal text)
                // and clamp weeks to the UI's allowed range.
                var config = try JSONDecoder().decode(HabitsHeatmapConfig.self, from: data)
                config.habitName = "Habit"
                config.weeksToShow = max(4, min(config.weeksToShow, 20))
                return try JSONEncoder().encode(config)
            case .quote:
                var config = try JSONDecoder().decode(QuoteConfig.self, from: data)
                config.text = clipped(config.text, maxLength: 500)
                config.author = clipped(config.author, maxLength: 120)
                // An unknown pack id (e.g. from a newer app version) falls
                // back to the user's custom text instead of a broken panel.
                if config.source == .pack,
                   config.packID.flatMap({ QuotePackLibrary.pack(id: $0) }) == nil {
                    config.source = .custom
                    config.packID = nil
                }
                return try JSONEncoder().encode(config)
            case .countdown:
                var config = try JSONDecoder().decode(CountdownConfig.self, from: data)
                config.eventName = clipped(config.eventName, maxLength: 120)
                config.beforeText = clipped(config.beforeText, maxLength: 80)
                config.afterText = clipped(config.afterText, maxLength: 80)
                config.todayText = clipped(config.todayText, maxLength: 80)
                return try JSONEncoder().encode(config)
            case .notes:
                var config = try JSONDecoder().decode(NotesConfig.self, from: data)
                config.noteText = ""
                config.maxLines = min(max(config.maxLines, 1), 12)
                return try JSONEncoder().encode(config)
            case .monthlyCalendar:
                let config = try JSONDecoder().decode(MonthlyCalendarConfig.self, from: data)
                return try JSONEncoder().encode(config)
            }
        } catch let error as TemplateSharingError {
            throw error
        } catch {
            throw TemplateSharingError.invalidContent
        }
    }

    private static func clipped(_ value: String, maxLength: Int) -> String {
        String(value.prefix(maxLength))
    }

    private static func sanitizedFileName(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let sanitized = value.unicodeScalars
            .map { allowed.contains($0) ? Character(String($0)) : "-" }
        let result = String(sanitized)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(48)
        return result.isEmpty ? "Lock-Screen-Template" : String(result)
    }
}

private struct SharedTemplateDocument: Codable {
    let kind: String
    let version: Int
    let name: String
    let templateDescription: String
    let layoutType: LayoutType
    let requiresPro: Bool
    let panels: [SharedPanel]
}

private struct SharedPanel: Codable {
    let panelType: PanelType
    let sortOrder: Int
    let isVisible: Bool
    let title: String
    let showTitle: Bool
    let configData: Data?
}
