import AppIntents
import SwiftUI
import SwiftData
import UIKit

// MARK: - Intent 1: Generate Today Wallpaper

/// Generates a wallpaper using the "Today" mode — auto-selects the first
/// available template and renders with current date's data.
/// This is the free-tier intent, designed for simple daily automation.
struct GenerateTodayWallpaperIntent: AppIntent {
    static let title: LocalizedStringResource = "Generate Today Wallpaper"
    static let description = IntentDescription(
        "Creates a wallpaper image with today's agenda, priorities, and tasks.",
        categoryName: "Wallpaper"
    )
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let service = ExportService()
        let context = try ModelContext(sharedModelContainer())

        let descriptor = FetchDescriptor<WallpaperTemplate>(
            predicate: #Predicate { !$0.isPro },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        guard let template = try context.fetch(descriptor).first else {
            throw IntentError.noTemplateFound
        }

        let priorities = try context.fetch(FetchDescriptor<PriorityItem>())
        let todos = try context.fetch(FetchDescriptor<TodoItem>())

        let result = try await service.generateWallpaper(
            panels: template.panels,
            theme: nil,
            devicePreset: .current,
            priorities: priorities,
            todos: todos,
            format: .png,
            date: .now
        )

        let fileURL = try service.saveToTemporaryFile(result)
        let intentFile = IntentFile(
            fileURL: fileURL,
            filename: "today_wallpaper.png",
            type: .png
        )

        return .result(value: intentFile)
    }
}

// MARK: - Intent 2: Generate Wallpaper by Template

/// Generates a wallpaper using a specific template chosen by the user.
/// Pro intent — requires subscription for non-free templates.
struct GenerateWallpaperIntent: AppIntent {
    static let title: LocalizedStringResource = "Generate Wallpaper"
    static let description = IntentDescription(
        "Creates a wallpaper image using a specific template.",
        categoryName: "Wallpaper"
    )
    static let openAppWhenRun = false

    @Parameter(title: "Template")
    var templateName: TemplateNameEnum

    @Parameter(title: "Theme", default: .dark)
    var theme: ThemeEnum

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let service = ExportService()
        let context = try ModelContext(sharedModelContainer())

        let searchName = templateName.templateName
        let descriptor = FetchDescriptor<WallpaperTemplate>(
            predicate: #Predicate { $0.name == searchName }
        )
        guard let template = try context.fetch(descriptor).first else {
            throw IntentError.noTemplateFound
        }

        // Pro templates require subscription
        if template.isPro {
            let subManager = SubscriptionManager()
            await subManager.updatePurchasedProducts()
            guard subManager.isPro else {
                throw IntentError.proRequired
            }
        }

        let priorities = try context.fetch(FetchDescriptor<PriorityItem>())
        let todos = try context.fetch(FetchDescriptor<TodoItem>())

        let themeConfig = ThemeConfiguration(
            colorScheme: theme == .light ? .light : .dark,
            accentColor: .indigo
        )

        let result = try await service.generateWallpaper(
            panels: template.panels,
            theme: themeConfig,
            devicePreset: .current,
            priorities: priorities,
            todos: todos,
            format: .png,
            date: .now
        )

        let fileURL = try service.saveToTemporaryFile(result)
        let intentFile = IntentFile(
            fileURL: fileURL,
            filename: "wallpaper.png",
            type: .png
        )

        return .result(value: intentFile)
    }
}

// MARK: - Intent 3: Generate Wallpaper with Parameters

/// Advanced intent with full parameter control: date, theme, size, format.
/// Pro-only intent for power users and complex Shortcuts.
struct GenerateWallpaperWithParametersIntent: AppIntent {
    static let title: LocalizedStringResource = "Generate Wallpaper (Advanced)"
    static let description = IntentDescription(
        "Creates a wallpaper image with full control over date, theme, device preset, and format.",
        categoryName: "Wallpaper"
    )
    static let openAppWhenRun = false

    @Parameter(title: "Template")
    var templateName: TemplateNameEnum

    @Parameter(title: "Date", description: "The date to generate the wallpaper for (defaults to today).")
    var date: Date?

    @Parameter(title: "Theme", default: .dark)
    var theme: ThemeEnum

    @Parameter(title: "Device", default: .auto)
    var device: DeviceEnum

    @Parameter(title: "Accent Color", default: .indigo)
    var accent: AccentEnum

    @Parameter(title: "Format", default: .png)
    var format: FormatEnum

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        // Pro-only intent
        let subManager = SubscriptionManager()
        await subManager.updatePurchasedProducts()
        guard subManager.isPro else {
            throw IntentError.proRequired
        }

        let service = ExportService()
        let context = try ModelContext(sharedModelContainer())

        let searchName = templateName.templateName
        let descriptor = FetchDescriptor<WallpaperTemplate>(
            predicate: #Predicate { $0.name == searchName }
        )
        guard let template = try context.fetch(descriptor).first else {
            throw IntentError.noTemplateFound
        }

        let priorities = try context.fetch(FetchDescriptor<PriorityItem>())
        let todos = try context.fetch(FetchDescriptor<TodoItem>())

        let themeConfig = ThemeConfiguration(
            colorScheme: theme == .light ? .light : .dark,
            accentColor: accent.accentOption
        )

        let targetDate = date ?? .now
        let preset = device.devicePreset
        let imageFormat: ImageFormat = format == .jpeg ? .jpeg : .png

        let result = try await service.generateWallpaper(
            panels: template.panels,
            theme: themeConfig,
            devicePreset: preset,
            priorities: priorities,
            todos: todos,
            format: imageFormat,
            date: targetDate
        )

        let fileURL = try service.saveToTemporaryFile(result)
        let intentFile = IntentFile(
            fileURL: fileURL,
            filename: "wallpaper.\(imageFormat.fileExtension)",
            type: imageFormat == .png ? .png : .jpeg
        )

        return .result(value: intentFile)
    }
}

// MARK: - Intent Enums (Shortcuts Parameters)

enum TemplateNameEnum: String, AppEnum {
    case todayDashboard = "today_dashboard"
    case minimalAgenda = "minimal_agenda"
    case priorityFocus = "priority_focus"
    case weeklyOverview = "weekly_overview"
    case darkFocus = "dark_focus"
    case splitLayout = "split_layout"
    case countdown = "countdown"
    case morningBriefing = "morning_briefing"
    case studentPlanner = "student_planner"
    case fitness = "fitness"
    case meetingDay = "meeting_day"
    case minimalNotes = "minimal_notes"
    case fullDashboard = "full_dashboard"

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Template")

    static let caseDisplayRepresentations: [TemplateNameEnum: DisplayRepresentation] = [
        .todayDashboard: "Today Dashboard",
        .minimalAgenda: "Minimal Agenda",
        .priorityFocus: "Priority Focus",
        .weeklyOverview: "Weekly Overview",
        .darkFocus: "Dark Focus",
        .splitLayout: "Split Layout",
        .countdown: "Countdown",
        .morningBriefing: "Morning Briefing",
        .studentPlanner: "Student Planner",
        .fitness: "Fitness",
        .meetingDay: "Meeting Day",
        .minimalNotes: "Minimal Notes",
        .fullDashboard: "Full Dashboard",
    ]

    var templateName: String {
        switch self {
        case .todayDashboard: return "Today Dashboard"
        case .minimalAgenda: return "Minimal Agenda"
        case .priorityFocus: return "Priority Focus"
        case .weeklyOverview: return "Weekly Overview"
        case .darkFocus: return "Dark Focus"
        case .splitLayout: return "Split Layout"
        case .countdown: return "Countdown"
        case .morningBriefing: return "Morning Briefing"
        case .studentPlanner: return "Student Planner"
        case .fitness: return "Fitness"
        case .meetingDay: return "Meeting Day"
        case .minimalNotes: return "Minimal Notes"
        case .fullDashboard: return "Full Dashboard"
        }
    }
}

enum ThemeEnum: String, AppEnum {
    case dark, light

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Theme")
    static let caseDisplayRepresentations: [ThemeEnum: DisplayRepresentation] = [
        .dark: "Dark",
        .light: "Light",
    ]
}

enum DeviceEnum: String, AppEnum {
    case auto
    // iPhone 17
    case iPhone17ProMax = "iphone17promax"
    case iPhone17Pro = "iphone17pro"
    case iPhone17Air = "iphone17air"
    case iPhone17 = "iphone17"
    // iPhone 16
    case iPhone16ProMax = "iphone16promax"
    case iPhone16Pro = "iphone16pro"
    case iPhone16Plus = "iphone16plus"
    case iPhone16 = "iphone16"
    case iPhone16e = "iphone16e"
    // iPhone 15
    case iPhone15ProMax = "iphone15promax"
    case iPhone15Pro = "iphone15pro"
    case iPhone15Plus = "iphone15plus"
    case iPhone15 = "iphone15"
    // iPhone 14
    case iPhone14ProMax = "iphone14promax"
    case iPhone14Pro = "iphone14pro"
    case iPhone14Plus = "iphone14plus"
    case iPhone14 = "iphone14"
    // iPhone 13
    case iPhone13ProMax = "iphone13promax"
    case iPhone13Pro = "iphone13pro"
    case iPhone13 = "iphone13"
    case iPhone13Mini = "iphone13mini"
    // iPhone 12
    case iPhone12ProMax = "iphone12promax"
    case iPhone12Pro = "iphone12pro"
    case iPhone12 = "iphone12"
    case iPhone12Mini = "iphone12mini"
    // iPhone SE
    case iPhoneSE3 = "iphonese3"

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Device")
    static let caseDisplayRepresentations: [DeviceEnum: DisplayRepresentation] = [
        .auto: "Auto-detect",
        .iPhone17ProMax: "iPhone 17 Pro Max",
        .iPhone17Pro: "iPhone 17 Pro",
        .iPhone17Air: "iPhone 17 Air",
        .iPhone17: "iPhone 17",
        .iPhone16ProMax: "iPhone 16 Pro Max",
        .iPhone16Pro: "iPhone 16 Pro",
        .iPhone16Plus: "iPhone 16 Plus",
        .iPhone16: "iPhone 16",
        .iPhone16e: "iPhone 16e",
        .iPhone15ProMax: "iPhone 15 Pro Max",
        .iPhone15Pro: "iPhone 15 Pro",
        .iPhone15Plus: "iPhone 15 Plus",
        .iPhone15: "iPhone 15",
        .iPhone14ProMax: "iPhone 14 Pro Max",
        .iPhone14Pro: "iPhone 14 Pro",
        .iPhone14Plus: "iPhone 14 Plus",
        .iPhone14: "iPhone 14",
        .iPhone13ProMax: "iPhone 13 Pro Max",
        .iPhone13Pro: "iPhone 13 Pro",
        .iPhone13: "iPhone 13",
        .iPhone13Mini: "iPhone 13 mini",
        .iPhone12ProMax: "iPhone 12 Pro Max",
        .iPhone12Pro: "iPhone 12 Pro",
        .iPhone12: "iPhone 12",
        .iPhone12Mini: "iPhone 12 mini",
        .iPhoneSE3: "iPhone SE (3rd gen)",
    ]

    var devicePreset: DevicePreset {
        switch self {
        case .auto: return .current
        default:
            return DevicePreset.allPresets.first { $0.id == rawValue } ?? .current
        }
    }
}

enum FormatEnum: String, AppEnum {
    case png, jpeg

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Image Format")
    static let caseDisplayRepresentations: [FormatEnum: DisplayRepresentation] = [
        .png: "PNG",
        .jpeg: "JPEG",
    ]
}

enum AccentEnum: String, AppEnum {
    case indigo, teal, orange, rose, blue, mint

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Accent Color")
    static let caseDisplayRepresentations: [AccentEnum: DisplayRepresentation] = [
        .indigo: "Indigo",
        .teal: "Teal",
        .orange: "Orange",
        .rose: "Rose",
        .blue: "Blue",
        .mint: "Mint",
    ]

    var accentOption: AccentColorOption {
        AccentColorOption(rawValue: rawValue) ?? .indigo
    }
}

// MARK: - Shortcuts Provider

struct LockScreenStudioShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GenerateTodayWallpaperIntent(),
            phrases: [
                "Generate today's wallpaper with \(.applicationName)",
                "Create today's lock screen with \(.applicationName)",
                "Make my daily wallpaper with \(.applicationName)",
            ],
            shortTitle: "Today Wallpaper",
            systemImageName: "photo.artframe"
        )
        AppShortcut(
            intent: GenerateWallpaperIntent(),
            phrases: [
                "Generate a wallpaper with \(.applicationName)",
                "Create a lock screen with \(.applicationName)",
            ],
            shortTitle: "Generate Wallpaper",
            systemImageName: "rectangle.on.rectangle"
        )
    }
}

// MARK: - Errors

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case noTemplateFound
    case proRequired
    case generationFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noTemplateFound:
            return "No matching template found. Open Lock Screen Studio to set up a template."
        case .proRequired:
            return "This template requires Lock Screen Studio Pro."
        case .generationFailed:
            return "Failed to generate wallpaper. Please try again."
        }
    }
}

// MARK: - Shared Model Container (for Intents)

/// Provides access to the shared SwiftData container from intents.
/// Must match the container configuration in the app.
private func sharedModelContainer() throws -> ModelContainer {
    let schema = Schema([
        DashboardProject.self,
        WallpaperTemplate.self,
        PanelConfiguration.self,
        ThemeConfiguration.self,
        ExportPreset.self,
        TodoItem.self,
        PriorityItem.self,
        ExportHistoryItem.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    return try ModelContainer(for: schema, configurations: [config])
}
