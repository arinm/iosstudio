import XCTest
import EventKit
@testable import LockScreenStudio

/// Renders the wallpapers that appear in the App Store screenshots, through the
/// app's own data builder and renderer, from data seeded into the simulator's
/// real Calendar and Reminders. Only Health is faked, through the same
/// `HealthProviding` seam the app uses.
///
/// Skipped unless `APPSTORE_SHOTS_DIR` is set, so it never runs in the suite:
///
///     TEST_RUNNER_APPSTORE_SHOTS_DIR=<dir> xcodebuild test \
///       -only-testing:LockScreenStudioTests/AppStoreWallpaperRenders ...
///
/// Grant the app Calendar and Reminders access on that simulator first
/// (`xcrun simctl privacy <udid> grant calendar com.lockscreenstudio.app`),
/// and pin the lock screen to the same day with `simctl status_bar`.
@MainActor
final class AppStoreWallpaperRenders: XCTestCase {

    /// Tuesday 10 March 2026, 09:41 — the day the screenshots are set on.
    private let day: Date = {
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 10; c.hour = 9; c.minute = 41
        return Calendar.current.date(from: c)!
    }()

    private var outputDir: URL!
    private let store = EKEventStore()

    override func setUp() async throws {
        guard let dir = ProcessInfo.processInfo.environment["APPSTORE_SHOTS_DIR"] else {
            throw XCTSkip("Set APPSTORE_SHOTS_DIR to render the App Store wallpapers")
        }
        outputDir = URL(fileURLWithPath: dir)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        // Only after a run that set them; a skipped run must not touch the
        // app's settings on whatever simulator the suite ran on.
        guard outputDir != nil else { return }
        for key in ["backgroundMode", "selectedColorScheme", "selectedAccent", "fontColor",
                    "fontScale", "contentPosition", "topPadding"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - The wallpapers

    func testDashboard() async throws {
        try await seedEvents([
            (9, 30, "Design review"),
            (12, 30, "Lunch with Maya"),
            (15, 0, "Dentist"),
            (18, 30, "Yoga class"),
        ])
        let agenda = PanelConfiguration(panelType: .agenda, sortOrder: 0, title: "Today")
        agenda.encodeConfig(AgendaConfig())
        let top = PanelConfiguration(panelType: .topThree, sortOrder: 1, title: "Top 3")
        top.encodeConfig(TopThreeConfig())
        let todo = PanelConfiguration(panelType: .todo, sortOrder: 2, title: "To-Do")
        todo.encodeConfig(TodoConfig(showCompleted: true, maxItems: 4))

        try await render("wall_dashboard", background: "gradient_deepPurple",
                         panels: [agenda, top, todo],
                         priorities: [
                            PriorityItem(text: "Finish the pitch deck", rank: 1, date: day),
                            PriorityItem(text: "Call the landlord", rank: 2, date: day),
                            PriorityItem(text: "30-minute run", rank: 3, date: day),
                         ],
                         todos: [
                            TodoItem(text: "Book flights to Tokyo", isCompleted: true, sortOrder: 0),
                            TodoItem(text: "Buy Leo's birthday gift", sortOrder: 1),
                            TodoItem(text: "Renew passport", sortOrder: 2),
                            TodoItem(text: "Water the plants", sortOrder: 3),
                         ])
    }

    func testReminders() async throws {
        let list = try await seedReminders(list: "Errands", [
            "Pick up dry cleaning",
            "Pay the electricity bill",
            "Order contact lenses",
            "Send Sara the photos",
            "Return the library books",
        ])
        let todo = PanelConfiguration(panelType: .todo, sortOrder: 0, title: "Errands")
        todo.encodeConfig(TodoConfig(maxItems: 5, source: .appleReminders,
                                     reminderListIdentifier: list.calendarIdentifier))
        let top = PanelConfiguration(panelType: .topThree, sortOrder: 1, title: "Top 3")
        top.encodeConfig(TopThreeConfig())

        try await render("wall_reminders", background: "light", accent: "blue",
                         panels: [todo, top],
                         priorities: [
                            PriorityItem(text: "Send the Q1 report", rank: 1, date: day),
                            PriorityItem(text: "Plan the team offsite", rank: 2, date: day),
                            PriorityItem(text: "Call Grandma", rank: 3, date: day),
                         ])
    }

    func testCountdown() async throws {
        let countdown = PanelConfiguration(panelType: .countdown, sortOrder: 0, title: "Countdown")
        var config = CountdownConfig()
        config.eventName = "Tokyo"
        config.targetDate = Calendar.current.date(byAdding: .day, value: 12, to: day)!
        countdown.encodeConfig(config)
        countdown.isTitleShown = false
        let notes = PanelConfiguration(panelType: .notes, sortOrder: 1, title: "Pack")
        notes.encodeConfig(NotesConfig(noteText: "JR Pass\nTravel adapter\nCamera + spare battery"))

        try await render("wall_countdown", background: "gradient_sunset", accent: "orange",
                         panels: [countdown, notes])
    }

    func testStreak() async throws {
        let heatmap = PanelConfiguration(panelType: .habitsHeatmap, sortOrder: 0, title: "Daily steps")
        heatmap.encodeConfig(HabitsHeatmapConfig(habitName: "Steps", weeksToShow: 16, source: .health))
        let quote = PanelConfiguration(panelType: .quote, sortOrder: 1, title: "Today")
        quote.isTitleShown = false
        quote.encodeConfig(QuoteConfig(text: "We are what we repeatedly do.", author: "Will Durant"))

        try await render("wall_streak", background: "gradient_forest", accent: "mint",
                         panels: [heatmap, quote],
                         health: Self.stepHistory(endingOn: day, streak: 23))
    }

    // MARK: - Rendering

    private func render(
        _ name: String,
        background: String,
        accent: String = "indigo",
        panels: [PanelConfiguration],
        priorities: [PriorityItem] = [],
        todos: [TodoItem] = [],
        health: [Date: Int] = [:]
    ) async throws {
        let defaults = UserDefaults.standard
        defaults.set(background, forKey: "backgroundMode")
        defaults.set(background == "light" ? "light" : "dark", forKey: "selectedColorScheme")
        defaults.set(accent, forKey: "selectedAccent")
        defaults.set("auto", forKey: "fontColor")
        // XL, the largest size the editor offers, so the wallpaper still reads
        // once the phone is scaled down into a screenshot.
        defaults.set(1.4, forKey: "fontScale")
        defaults.set("center", forKey: "contentPosition")
        defaults.set(0.0, forKey: "topPadding")

        // The same steps as `ExportService.generateWallpaper`, with Health
        // swapped for a fixed history.
        let builder = PanelDataBuilder(healthService: FixedHealth(counts: health))
        let data = await builder.buildPanelData(for: panels, priorities: priorities,
                                                todos: todos, date: day)
        let (position, clockPadding) = ExportService.readLayoutSettings()
        let preset = DevicePreset.allPresets.first { $0.id == "iphone18promax" }!
        let result = try WallpaperRenderer().render(.init(
            panels: data,
            theme: ExportService.buildRenderTheme(from: nil),
            devicePreset: preset,
            contentPosition: position,
            clockTopPadding: clockPadding
        ))
        try result.imageData.write(to: outputDir.appendingPathComponent("\(name).png"))
    }

    // MARK: - Seeding the simulator

    private func seedEvents(_ events: [(Int, Int, String)]) async throws {
        let granted = try await store.requestFullAccessToEvents()
        try XCTSkipUnless(granted, "grant Calendar access to com.lockscreenstudio.app first")
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        for old in store.events(matching: store.predicateForEvents(withStart: start, end: end, calendars: nil)) {
            try store.remove(old, span: .thisEvent, commit: false)
        }
        let target = try eventCalendar()
        for (hour, minute, title) in events {
            let event = EKEvent(eventStore: store)
            event.title = title
            event.startDate = cal.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
            event.endDate = event.startDate.addingTimeInterval(3600)
            event.calendar = target
            try store.save(event, span: .thisEvent, commit: false)
        }
        try store.commit()
    }

    private func eventCalendar() throws -> EKCalendar {
        if let existing = store.defaultCalendarForNewEvents { return existing }
        let created = EKCalendar(for: .event, eventStore: store)
        created.title = "Personal"
        created.source = try localSource()
        try store.saveCalendar(created, commit: true)
        return created
    }

    private func seedReminders(list title: String, _ items: [String]) async throws -> EKCalendar {
        let granted = try await store.requestFullAccessToReminders()
        try XCTSkipUnless(granted, "grant Reminders access to com.lockscreenstudio.app first")
        let list: EKCalendar
        if let existing = store.calendars(for: .reminder).first(where: { $0.title == title }) {
            list = existing
        } else {
            list = EKCalendar(for: .reminder, eventStore: store)
            list.title = title
            list.source = try store.defaultCalendarForNewReminders()?.source ?? localSource()
            try store.saveCalendar(list, commit: true)
        }
        let old: [EKReminder] = await withCheckedContinuation { done in
            store.fetchReminders(matching: store.predicateForReminders(in: [list])) {
                done.resume(returning: $0 ?? [])
            }
        }
        for reminder in old { try store.remove(reminder, commit: false) }
        for text in items {
            let reminder = EKReminder(eventStore: store)
            reminder.title = text
            reminder.calendar = list
            try store.save(reminder, commit: false)
        }
        try store.commit()
        return list
    }

    private func localSource() throws -> EKSource {
        guard let source = store.sources.first(where: { $0.sourceType == .local })
                ?? store.sources.first else {
            throw XCTSkip("the simulator has no calendar source")
        }
        return source
    }

    /// Mostly active days with a few rest days, ending in an unbroken streak.
    static func stepHistory(endingOn day: Date, streak: Int) -> [Date: Int] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: day)
        var counts: [Date: Int] = [:]
        var seed: UInt64 = 7
        for back in 0..<(16 * 7) {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let roll = Int(seed >> 33) % 100
            let date = cal.date(byAdding: .day, value: -back, to: today)!
            if back < streak {
                counts[date] = 4_000 + roll * 110      // 4k–15k: every level but empty
            } else if back == streak {
                counts[date] = 400                       // the day the streak started after
            } else {
                counts[date] = roll < 18 ? 300 : 2_000 + roll * 120
            }
        }
        return counts
    }
}

private struct FixedHealth: HealthProviding {
    let counts: [Date: Int]
    var isAvailable: Bool { true }
    func currentlyAuthorized() async -> Bool { true }
    func requestAccess() async -> Bool { true }
    func dailyStepCounts(from: Date, to: Date) async -> [Date: Int] {
        counts.filter { $0.key >= from && $0.key <= to }
    }
}
