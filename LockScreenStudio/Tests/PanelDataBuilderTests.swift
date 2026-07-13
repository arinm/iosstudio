import XCTest
@testable import LockScreenStudio

@MainActor
final class PanelDataBuilderTests: XCTestCase {
    func testLegacyLocalSourceRendersOnlyLocalTodos() async throws {
        let panel = PanelConfiguration(panelType: .todo)
        panel.encodeConfig(TodoConfig(maxItems: 5))
        let localTodo = TodoItem(text: "Local task")
        let provider = StubRemindersProvider(
            reminders: [ReminderSnapshot(id: "remote", title: "Remote task", isCompleted: false, dueDate: nil)]
        )
        let builder = PanelDataBuilder(remindersService: provider)

        let result = await builder.buildPanelData(
            for: [panel],
            priorities: [],
            todos: [localTodo]
        )

        let line = try XCTUnwrap(result.first?.lines.first)
        guard case let .todoItem(text, completed) = line else {
            return XCTFail("Expected a local todo line")
        }
        XCTAssertEqual(text, "Local task")
        XCTAssertFalse(completed)
        XCTAssertEqual(result.first?.lines.count, 1)
    }

    func testAppleRemindersSourceRendersOnlyReminderSnapshots() async throws {
        let panel = PanelConfiguration(panelType: .todo)
        panel.encodeConfig(TodoConfig(maxItems: 5, source: .appleReminders))
        let localTodo = TodoItem(text: "Local task")
        let provider = StubRemindersProvider(
            reminders: [ReminderSnapshot(id: "remote", title: "Remote task", isCompleted: false, dueDate: nil)]
        )
        let builder = PanelDataBuilder(remindersService: provider)

        let result = await builder.buildPanelData(
            for: [panel],
            priorities: [],
            todos: [localTodo]
        )

        let line = try XCTUnwrap(result.first?.lines.first)
        guard case let .todoItem(text, completed) = line else {
            return XCTFail("Expected an Apple Reminder line")
        }
        XCTAssertEqual(text, "Remote task")
        XCTAssertFalse(completed)
        XCTAssertEqual(result.first?.lines.count, 1)
    }

    func testAppleSourceFallsBackToLocalWhenAccessIsUnavailable() async throws {
        let panel = PanelConfiguration(panelType: .todo)
        panel.encodeConfig(TodoConfig(maxItems: 5, source: .appleReminders))
        let localTodo = TodoItem(text: "Safe local fallback")
        let provider = StubRemindersProvider(
            status: .denied,
            reminders: [ReminderSnapshot(id: "remote", title: "Remote task", isCompleted: false, dueDate: nil)]
        )
        let builder = PanelDataBuilder(remindersService: provider)

        let result = await builder.buildPanelData(
            for: [panel],
            priorities: [],
            todos: [localTodo]
        )

        let line = try XCTUnwrap(result.first?.lines.first)
        guard case let .todoItem(text, _) = line else {
            return XCTFail("Expected the local fallback todo")
        }
        XCTAssertEqual(text, "Safe local fallback")
        XCTAssertEqual(result.first?.lines.count, 1)
    }

    func testAppleSourceFallsBackToLocalWhenSelectedListWasDeleted() async throws {
        let panel = PanelConfiguration(panelType: .todo)
        panel.encodeConfig(
            TodoConfig(
                maxItems: 5,
                source: .appleReminders,
                reminderListIdentifier: "deleted-list"
            )
        )
        let localTodo = TodoItem(text: "Private safe fallback")
        let provider = StubRemindersProvider(
            reminders: [ReminderSnapshot(id: "remote", title: "Unselected list item", isCompleted: false, dueDate: nil)],
            listIsAvailable: false
        )
        let builder = PanelDataBuilder(remindersService: provider)

        let result = await builder.buildPanelData(
            for: [panel],
            priorities: [],
            todos: [localTodo]
        )

        let line = try XCTUnwrap(result.first?.lines.first)
        guard case let .todoItem(text, _) = line else {
            return XCTFail("Expected the local fallback todo")
        }
        XCTAssertEqual(text, "Private safe fallback")
        XCTAssertEqual(result.first?.lines.count, 1)
    }

    func testCombinedSourceKeepsLocalFirstAndAppliesSharedLimit() async throws {
        let panel = PanelConfiguration(panelType: .todo)
        panel.encodeConfig(TodoConfig(maxItems: 2, source: .combined))
        let localTodos = [
            TodoItem(text: "First local", sortOrder: 0),
            TodoItem(text: "Second local", sortOrder: 1),
        ]
        let provider = StubRemindersProvider(
            reminders: [ReminderSnapshot(id: "remote", title: "Remote task", isCompleted: false, dueDate: nil)]
        )
        let builder = PanelDataBuilder(remindersService: provider)

        let result = await builder.buildPanelData(
            for: [panel],
            priorities: [],
            todos: localTodos
        )

        let lines = try XCTUnwrap(result.first?.lines)
        XCTAssertEqual(lines.count, 2)
        guard case let .todoItem(firstText, _) = lines[0],
              case let .todoItem(secondText, _) = lines[1] else {
            return XCTFail("Expected todo lines")
        }
        XCTAssertEqual(firstText, "First local")
        XCTAssertEqual(secondText, "Second local")
    }
}

private struct StubRemindersProvider: RemindersProviding {
    var status: ReminderAuthorizationStatus = .authorized
    var reminders: [ReminderSnapshot]
    var listIsAvailable = true

    func currentAuthorizationStatus() async -> ReminderAuthorizationStatus { status }
    func requestAccess() async -> Bool { status == .authorized }
    func availableLists() async -> [ReminderListOption] { [] }
    func isListAvailable(_ identifier: String?) async -> Bool { listIsAvailable }

    func fetchReminders(
        filter: TodoConfig.ReminderFilter,
        listIdentifier: String?,
        referenceDate: Date
    ) async -> [ReminderSnapshot] {
        reminders
    }
}
