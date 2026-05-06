import Foundation
import SwiftData

/// Seeds the database with built-in templates on first launch.
struct TemplateSeeder {

    private static let currentSeedVersion = 4

    static func seedIfNeeded(context: ModelContext) {
        let storedVersion = UserDefaults.standard.integer(forKey: "templateSeedVersion")

        if storedVersion == 0 {
            // First launch: seed all templates
            let descriptor = FetchDescriptor<WallpaperTemplate>(
                predicate: #Predicate { $0.isBuiltIn }
            )
            let existing = (try? context.fetchCount(descriptor)) ?? 0
            guard existing == 0 else {
                UserDefaults.standard.set(currentSeedVersion, forKey: "templateSeedVersion")
                return
            }

            for template in builtInTemplates() {
                context.insert(template)
            }
            try? context.save()
            UserDefaults.standard.set(currentSeedVersion, forKey: "templateSeedVersion")
        } else if storedVersion < currentSeedVersion {
            // Incremental seed: add new templates that don't exist yet
            let descriptor = FetchDescriptor<WallpaperTemplate>(
                predicate: #Predicate { $0.isBuiltIn }
            )
            let existing = (try? context.fetch(descriptor)) ?? []
            let existingNames = Set(existing.map(\.name))

            for template in builtInTemplates() where !existingNames.contains(template.name) {
                context.insert(template)
            }
            try? context.save()
            UserDefaults.standard.set(currentSeedVersion, forKey: "templateSeedVersion")
        }
    }

    private static func builtInTemplates() -> [WallpaperTemplate] {
        [
            makeTodayDashboard(),
            makeMinimalAgenda(),
            makePriorityFocus(),
            makeWeeklyOverview(),
            makeDarkFocus(),
            makeSplitLayout(),
            makeCountdownDashboard(),
            makeMorningBriefing(),
            makeStudentPlanner(),
            makeFitnessTracker(),
            makeMeetingDay(),
            makeMinimalNotes(),
            makeFullDashboard(),
            makeJustTodo(),
        ]
    }

    private static func makeJustTodo() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Just To-Do",
            description: "A focused list — just date and your tasks.",
            layoutType: .minimal,
            isPro: false,
            sortOrder: 13
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .todo, sortOrder: 1, title: "To-Do"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true, dateFormat: .long))
        // Show completed so toggling from the widget gives visible strikethrough feedback.
        panels[1].encodeConfig(TodoConfig(showCompleted: true, maxItems: 8))

        template.panels = panels
        return template
    }

    // MARK: - Template Definitions

    private static func makeTodayDashboard() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Today Dashboard",
            description: "Your complete daily overview with agenda, priorities, and to-dos.",
            layoutType: .singleColumn,
            isPro: false,
            sortOrder: 0
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .agenda, sortOrder: 1, title: "Agenda"),
            PanelConfiguration(panelType: .topThree, sortOrder: 2, title: "Top 3"),
            PanelConfiguration(panelType: .todo, sortOrder: 3, title: "To-Do"),
        ]

        // Set default configs
        panels[0].encodeConfig(DateTimeConfig())
        panels[1].encodeConfig(AgendaConfig(dateRange: .today, maxEvents: 4, showTime: true))
        panels[2].encodeConfig(TopThreeConfig())
        panels[3].encodeConfig(TodoConfig(showCompleted: false, maxItems: 4))

        template.panels = panels
        return template
    }

    private static func makeMinimalAgenda() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Minimal Agenda",
            description: "Clean calendar view with just today's events.",
            layoutType: .minimal,
            isPro: false,
            sortOrder: 1
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .agenda, sortOrder: 1, title: "Today"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true, dateFormat: .long))
        panels[1].encodeConfig(AgendaConfig(dateRange: .today, maxEvents: 6, showTime: true))

        template.panels = panels
        return template
    }

    private static func makePriorityFocus() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Priority Focus",
            description: "Just your top 3 priorities — bold and clear.",
            layoutType: .minimal,
            isPro: true,
            sortOrder: 2
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .topThree, sortOrder: 1, title: "Focus"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true))
        panels[1].encodeConfig(TopThreeConfig())

        template.panels = panels
        return template
    }

    private static func makeWeeklyOverview() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Weekly Overview",
            description: "See the full week's events at a glance.",
            layoutType: .singleColumn,
            isPro: true,
            sortOrder: 3
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .agenda, sortOrder: 1, title: "This Week"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true))
        panels[1].encodeConfig(AgendaConfig(dateRange: .week, maxEvents: 8, showTime: true))

        template.panels = panels
        return template
    }

    private static func makeDarkFocus() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Dark Focus",
            description: "Minimal dark theme with agenda and priorities.",
            layoutType: .minimal,
            isPro: true,
            sortOrder: 4
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .topThree, sortOrder: 1, title: "Today"),
            PanelConfiguration(panelType: .agenda, sortOrder: 2, title: "Schedule"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true))
        panels[1].encodeConfig(TopThreeConfig())
        panels[2].encodeConfig(AgendaConfig(dateRange: .today, maxEvents: 4, showTime: true))

        template.panels = panels
        return template
    }

    private static func makeSplitLayout() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Split Layout",
            description: "Calendar on top, tasks on bottom — balanced view.",
            layoutType: .splitHorizontal,
            isPro: true,
            sortOrder: 5
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .agenda, sortOrder: 1, title: "Schedule"),
            PanelConfiguration(panelType: .todo, sortOrder: 2, title: "Tasks"),
        ]

        panels[0].encodeConfig(DateTimeConfig())
        panels[1].encodeConfig(AgendaConfig(dateRange: .today, maxEvents: 3, showTime: true))
        panels[2].encodeConfig(TodoConfig(showCompleted: false, maxItems: 4))

        template.panels = panels
        return template
    }

    private static func makeCountdownDashboard() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Countdown",
            description: "Track days until your next big event.",
            layoutType: .minimal,
            isPro: false,
            sortOrder: 6
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .countdown, sortOrder: 1, title: "Countdown"),
            PanelConfiguration(panelType: .topThree, sortOrder: 2, title: "Focus"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true))
        panels[1].encodeConfig(CountdownConfig(
            targetDate: Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now,
            eventName: "Launch Day"
        ))
        panels[2].encodeConfig(TopThreeConfig())

        template.panels = panels
        return template
    }

    private static func makeMorningBriefing() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Morning Briefing",
            description: "Start your day with agenda and a motivational note.",
            layoutType: .singleColumn,
            isPro: false,
            sortOrder: 7
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .agenda, sortOrder: 1, title: "Today"),
            PanelConfiguration(panelType: .notes, sortOrder: 2, title: "Note"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true))
        panels[1].encodeConfig(AgendaConfig(dateRange: .today, maxEvents: 4, showTime: true))
        panels[2].encodeConfig(NotesConfig(noteText: "Make today count.", maxLines: 2))

        template.panels = panels
        return template
    }

    private static func makeStudentPlanner() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Student Planner",
            description: "Track exams, assignments, and daily tasks.",
            layoutType: .singleColumn,
            isPro: false,
            sortOrder: 8
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .countdown, sortOrder: 1, title: "Exam"),
            PanelConfiguration(panelType: .todo, sortOrder: 2, title: "Assignments"),
            PanelConfiguration(panelType: .notes, sortOrder: 3, title: "Reminders"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true))
        panels[1].encodeConfig(CountdownConfig(
            targetDate: Calendar.current.date(byAdding: .day, value: 45, to: .now) ?? .now,
            eventName: "Final Exam"
        ))
        panels[2].encodeConfig(TodoConfig(showCompleted: false, maxItems: 4))
        panels[3].encodeConfig(NotesConfig(noteText: "", maxLines: 3))

        template.panels = panels
        return template
    }

    private static func makeFitnessTracker() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Fitness",
            description: "Stay focused on your fitness goals.",
            layoutType: .minimal,
            isPro: true,
            sortOrder: 9
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .countdown, sortOrder: 1, title: "Goal"),
            PanelConfiguration(panelType: .topThree, sortOrder: 2, title: "Workout"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true))
        panels[1].encodeConfig(CountdownConfig(
            targetDate: Calendar.current.date(byAdding: .day, value: 60, to: .now) ?? .now,
            eventName: "Race Day"
        ))
        panels[2].encodeConfig(TopThreeConfig())

        template.panels = panels
        return template
    }

    private static func makeMeetingDay() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Meeting Day",
            description: "Full schedule with priorities for busy days.",
            layoutType: .singleColumn,
            isPro: true,
            sortOrder: 10
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .agenda, sortOrder: 1, title: "Schedule"),
            PanelConfiguration(panelType: .topThree, sortOrder: 2, title: "Priorities"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true))
        panels[1].encodeConfig(AgendaConfig(dateRange: .today, maxEvents: 8, showTime: true))
        panels[2].encodeConfig(TopThreeConfig())

        template.panels = panels
        return template
    }

    private static func makeMinimalNotes() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Minimal Notes",
            description: "Just the date and your personal note.",
            layoutType: .minimal,
            isPro: false,
            sortOrder: 11
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .notes, sortOrder: 1, title: "Note"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true, dateFormat: .long))
        panels[1].encodeConfig(NotesConfig(noteText: "", maxLines: 6))

        template.panels = panels
        return template
    }

    private static func makeFullDashboard() -> WallpaperTemplate {
        let template = WallpaperTemplate(
            name: "Full Dashboard",
            description: "Everything at a glance — the ultimate overview.",
            layoutType: .singleColumn,
            isPro: true,
            sortOrder: 12
        )

        let panels = [
            PanelConfiguration(panelType: .dateTime, sortOrder: 0, title: nil),
            PanelConfiguration(panelType: .agenda, sortOrder: 1, title: "Agenda"),
            PanelConfiguration(panelType: .topThree, sortOrder: 2, title: "Top 3"),
            PanelConfiguration(panelType: .countdown, sortOrder: 3, title: "Countdown"),
            PanelConfiguration(panelType: .todo, sortOrder: 4, title: "To-Do"),
            PanelConfiguration(panelType: .notes, sortOrder: 5, title: "Notes"),
        ]

        panels[0].encodeConfig(DateTimeConfig(showDayOfWeek: true))
        panels[1].encodeConfig(AgendaConfig(dateRange: .today, maxEvents: 3, showTime: true))
        panels[2].encodeConfig(TopThreeConfig())
        panels[3].encodeConfig(CountdownConfig(
            targetDate: Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now,
            eventName: "Launch Day"
        ))
        panels[4].encodeConfig(TodoConfig(showCompleted: false, maxItems: 3))
        panels[5].encodeConfig(NotesConfig(noteText: "", maxLines: 2))

        template.panels = panels
        return template
    }
}
