import SwiftUI
import SwiftData

struct EditorView: View {
    @Bindable var template: WallpaperTemplate
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @Query(sort: \TodoItem.sortOrder) private var todos: [TodoItem]
    @Query private var priorities: [PriorityItem]

    @State private var showThemePicker = false
    @State private var showPreview = false
    @State private var showPanelConfig: PanelConfiguration?
    @State private var showPaywall = false
    @State private var showShortcutsWizard = false
    @State private var showAddPanel = false

    // Quick-edit state for Top 3 priorities
    @State private var priority1 = ""
    @State private var priority2 = ""
    @State private var priority3 = ""

    private var sortedPanels: [PanelConfiguration] {
        template.panels.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                panelListSection
                if template.panels.contains(where: { $0.panelType == .topThree && $0.isVisible }) {
                    quickEditSection
                }
                if template.panels.contains(where: { $0.panelType == .todo && $0.isVisible }) {
                    todoEditSection
                }
                layoutSection
                themeButton
                automationButton
                generateButton
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPreview = true
                } label: {
                    Image(systemName: "eye")
                }
                .accessibilityLabel("Preview wallpaper")
            }
        }
        .sheet(isPresented: $showThemePicker) {
            ThemePickerSheet()
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showPreview) {
            PreviewView(
                template: template,
                priorities: currentPriorities(),
                todos: todos
            )
        }
        .sheet(item: $showPanelConfig) { panel in
            PanelConfigSheet(panel: panel)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showShortcutsWizard) {
            ShortcutsWizardSheet()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showAddPanel) {
            AddPanelSheet { type in
                addPanel(type: type)
            }
            .presentationDetents([.medium])
        }
        .onAppear { loadPriorities() }
    }

    // MARK: - Panels List

    private var panelListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Panels")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(sortedPanels) { panel in
                    panelRow(panel)
                        .contextMenu {
                            if panel.sortOrder > 0 {
                                Button {
                                    movePanel(panel, direction: .up)
                                } label: {
                                    Label("Move Up", systemImage: "arrow.up")
                                }
                            }
                            if panel.sortOrder < sortedPanels.count - 1 {
                                Button {
                                    movePanel(panel, direction: .down)
                                } label: {
                                    Label("Move Down", systemImage: "arrow.down")
                                }
                            }
                            Divider()
                            Button(role: .destructive) {
                                deletePanel(panel)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }

                    if panel.id != sortedPanels.last?.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Add Panel button
            Button {
                if subscriptionManager.isPro {
                    showAddPanel = true
                } else {
                    showPaywall = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.indigo)
                    Text("Add Panel")
                        .font(.subheadline)
                    if !subscriptionManager.isPro {
                        Text("PRO")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.indigo)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private func panelRow(_ panel: PanelConfiguration) -> some View {
        Button {
            showPanelConfig = panel
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.tertiary)
                    .font(.subheadline)

                Image(systemName: panel.panelType.systemImage)
                    .foregroundStyle(.indigo)
                    .frame(width: 24)

                Text(panel.title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { panel.isVisible },
                    set: { panel.isVisible = $0 }
                ))
                .labelsHidden()
                .tint(.indigo)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityLabel("\(panel.title) panel, \(panel.isVisible ? "visible" : "hidden")")
        .accessibilityHint("Double tap to configure")
    }

    // MARK: - Quick Edit (Top 3)

    private var quickEditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top 3")
                .font(.headline)

            VStack(spacing: 12) {
                priorityField("Priority 1", text: $priority1)
                priorityField("Priority 2", text: $priority2)
                priorityField("Priority 3", text: $priority3)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func priorityField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("What matters most?", text: text)
                .textFieldStyle(.plain)
                .font(.body)
                .onChange(of: text.wrappedValue) { _, _ in savePriorities() }
        }
    }

    // MARK: - Todo Edit

    @State private var newTodoText = ""

    private var todoPanelTitle: String {
        template.panels.first(where: { $0.panelType == .todo && $0.isVisible })?.title ?? "To-Do"
    }

    private var todoEditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(todoPanelTitle)
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(todos) { todo in
                    HStack(spacing: 12) {
                        Button {
                            todo.isCompleted.toggle()
                        } label: {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(todo.isCompleted ? .green : .secondary)
                        }

                        Text(todo.text)
                            .strikethrough(todo.isCompleted)
                            .foregroundStyle(todo.isCompleted ? .secondary : .primary)

                        Spacer()

                        Button {
                            modelContext.delete(todo)
                            try? modelContext.save()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if todo.id != todos.last?.id {
                        Divider().padding(.leading, 52)
                    }
                }

                // Add new todo
                HStack(spacing: 12) {
                    Button {
                        addTodo()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.indigo)
                            .font(.title3)
                    }
                    .disabled(newTodoText.trimmingCharacters(in: .whitespaces).isEmpty)

                    TextField("Add a task...", text: $newTodoText)
                        .submitLabel(.done)
                        .onSubmit {
                            addTodo()
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func addTodo() {
        let text = newTodoText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let todo = TodoItem(text: text, sortOrder: todos.count)
        modelContext.insert(todo)
        try? modelContext.save()
        newTodoText = ""
    }

    // MARK: - Layout Section

    @AppStorage("fontScale") private var fontScale: Double = 1.0
    @AppStorage("contentPosition") private var contentPosition: String = "center"
    @AppStorage("topPadding") private var topPadding: Double = 0

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Font Size
            VStack(alignment: .leading, spacing: 8) {
                Text("Font Size")
                    .font(.subheadline.bold())

                HStack(spacing: 8) {
                    ForEach(FontScaleOption.allCases) { option in
                        let isSelected = abs(fontScale - option.scale) < 0.01
                        Button {
                            fontScale = option.scale
                        } label: {
                            VStack(spacing: 4) {
                                Text("Aa")
                                    .font(.system(size: option.previewSize, weight: .medium))
                                Text(option.label)
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isSelected ? Color.indigo.opacity(0.15) : Color(.tertiarySystemBackground))
                            .foregroundStyle(isSelected ? .indigo : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.indigo : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Text Position
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Position")
                    .font(.subheadline.bold())

                HStack(spacing: 8) {
                    layoutPositionButton("Top", value: "top", icon: "arrow.up.to.line")
                    layoutPositionButton("Center", value: "center", icon: "arrow.up.and.down")
                    layoutPositionButton("Bottom", value: "bottom", icon: "arrow.down.to.line")
                }
            }

            // Top Padding
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Top Padding")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(topPadding == 0 ? "None" : "\(Int(topPadding))px")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Slider(value: $topPadding, in: 0...400, step: 20)
                    .tint(.indigo)

                Text("Adjust to avoid the Lock Screen clock.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func layoutPositionButton(_ label: String, value: String, icon: String) -> some View {
        let isSelected = contentPosition == value

        return Button {
            contentPosition = value
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                Text(label)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.indigo.opacity(0.15) : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .indigo : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.indigo : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Theme

    private var themeButton: some View {
        Button {
            showThemePicker = true
        } label: {
            HStack {
                Image(systemName: "paintbrush")
                Text("Theme")
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

    private var automationButton: some View {
        Button {
            showShortcutsWizard = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Automation")
                        .font(.subheadline)
                    Text("Auto-generate via Shortcuts")
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

    private var generateButton: some View {
        Button {
            if template.isPro && !subscriptionManager.isPro {
                showPaywall = true
            } else {
                // Save panels for background auto-refresh
                BackgroundTaskManager.savePanelsForRefresh(sortedPanels)
                showPreview = true
            }
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Generate")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
    }

    // MARK: - Priority Persistence

    private func loadPriorities() {
        let today = Calendar.current.startOfDay(for: .now)
        let todayPriorities = priorities
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.rank < $1.rank }

        priority1 = todayPriorities.first { $0.rank == 1 }?.text ?? ""
        priority2 = todayPriorities.first { $0.rank == 2 }?.text ?? ""
        priority3 = todayPriorities.first { $0.rank == 3 }?.text ?? ""
    }

    private func savePriorities() {
        let today = Calendar.current.startOfDay(for: .now)

        // Remove old priorities for today
        let todayPriorities = priorities.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        for p in todayPriorities {
            modelContext.delete(p)
        }

        // Insert new ones
        let texts = [(1, priority1), (2, priority2), (3, priority3)]
        for (rank, text) in texts where !text.isEmpty {
            let item = PriorityItem(text: text, rank: rank, date: today)
            modelContext.insert(item)
        }

        try? modelContext.save()
    }

    private func currentPriorities() -> [PriorityItem] {
        let today = Calendar.current.startOfDay(for: .now)
        return priorities
            .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.rank < $1.rank }
    }

    // MARK: - Panel Management

    private enum MoveDirection { case up, down }

    private func movePanel(_ panel: PanelConfiguration, direction: MoveDirection) {
        let panels = sortedPanels
        guard let index = panels.firstIndex(where: { $0.id == panel.id }) else { return }

        let swapIndex = direction == .up ? index - 1 : index + 1
        guard panels.indices.contains(swapIndex) else { return }

        let otherPanel = panels[swapIndex]
        let temp = panel.sortOrder
        panel.sortOrder = otherPanel.sortOrder
        otherPanel.sortOrder = temp

        try? modelContext.save()
    }

    private func deletePanel(_ panel: PanelConfiguration) {
        template.panels.removeAll { $0.id == panel.id }
        modelContext.delete(panel)

        // Re-index remaining panels
        for (i, p) in sortedPanels.enumerated() {
            p.sortOrder = i
        }

        try? modelContext.save()
    }

    private func addPanel(type: PanelType) {
        let nextOrder = (template.panels.map(\.sortOrder).max() ?? -1) + 1
        let panel = PanelConfiguration(panelType: type, sortOrder: nextOrder)

        // Set default config
        switch type {
        case .agenda:
            panel.encodeConfig(AgendaConfig())
        case .topThree:
            panel.encodeConfig(TopThreeConfig())
        case .todo:
            panel.encodeConfig(TodoConfig())
        case .dateTime:
            panel.encodeConfig(DateTimeConfig())
        case .countdown:
            panel.encodeConfig(CountdownConfig())
        case .notes:
            panel.encodeConfig(NotesConfig())
        case .habitsHeatmap:
            panel.encodeConfig(HabitsHeatmapConfig())
        case .quote:
            panel.encodeConfig(QuoteConfig())
        case .monthlyCalendar:
            panel.encodeConfig(MonthlyCalendarConfig())
        }

        template.panels.append(panel)
        try? modelContext.save()
    }
}

// MARK: - Panel Config Sheet

struct PanelConfigSheet: View {
    @Bindable var panel: PanelConfiguration
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Panel") {
                    TextField("Title", text: $panel.title)
                }

                switch panel.panelType {
                case .agenda:
                    agendaConfigSection
                case .topThree:
                    Section {
                        Text("Edit your priorities in the Top 3 section on the editor screen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                case .todo:
                    todoConfigSection
                case .dateTime:
                    dateTimeConfigSection
                case .countdown:
                    countdownConfigSection
                case .notes:
                    notesConfigSection
                case .quote:
                    quoteConfigSection
                case .habitsHeatmap:
                    habitsConfigSection
                case .monthlyCalendar:
                    monthlyCalendarConfigSection
                }
            }
            .navigationTitle(panel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var agendaConfigSection: some View {
        let config = panel.decodeConfig(AgendaConfig.self) ?? AgendaConfig()

        return Section("Agenda Settings") {
            Picker("Date Range", selection: Binding(
                get: { config.dateRange },
                set: { newValue in
                    var c = config
                    c.dateRange = newValue
                    panel.encodeConfig(c)
                }
            )) {
                Text("Today").tag(AgendaConfig.AgendaDateRange.today)
                Text("Tomorrow").tag(AgendaConfig.AgendaDateRange.tomorrow)
                Text("This Week").tag(AgendaConfig.AgendaDateRange.week)
            }

            Stepper("Max Events: \(config.maxEvents)", value: Binding(
                get: { config.maxEvents },
                set: { newValue in
                    var c = config
                    c.maxEvents = newValue
                    panel.encodeConfig(c)
                }
            ), in: 1...10)

            Toggle("Show Time", isOn: Binding(
                get: { config.showTime },
                set: { newValue in
                    var c = config
                    c.showTime = newValue
                    panel.encodeConfig(c)
                }
            ))
        }
    }

    private var todoConfigSection: some View {
        let config = panel.decodeConfig(TodoConfig.self) ?? TodoConfig()

        return Section("To-Do Settings") {
            Toggle("Show Completed", isOn: Binding(
                get: { config.showCompleted },
                set: { newValue in
                    var c = config
                    c.showCompleted = newValue
                    panel.encodeConfig(c)
                }
            ))

            Stepper("Max Items: \(config.maxItems)", value: Binding(
                get: { config.maxItems },
                set: { newValue in
                    var c = config
                    c.maxItems = newValue
                    panel.encodeConfig(c)
                }
            ), in: 1...10)
        }
    }

    private var dateTimeConfigSection: some View {
        let config = panel.decodeConfig(DateTimeConfig.self) ?? DateTimeConfig()

        return Section("Date & Time Settings") {
            Toggle("Show Day of Week", isOn: Binding(
                get: { config.showDayOfWeek },
                set: { newValue in
                    var c = config
                    c.showDayOfWeek = newValue
                    panel.encodeConfig(c)
                }
            ))

            Picker("Date Format", selection: Binding(
                get: { config.dateFormat },
                set: { newValue in
                    var c = config
                    c.dateFormat = newValue
                    panel.encodeConfig(c)
                }
            )) {
                Text("Short").tag(DateTimeConfig.DateFormatStyle.short)
                Text("Medium").tag(DateTimeConfig.DateFormatStyle.medium)
                Text("Long").tag(DateTimeConfig.DateFormatStyle.long)
            }
        }
    }

    private var countdownConfigSection: some View {
        let config = panel.decodeConfig(CountdownConfig.self) ?? CountdownConfig()

        return Section("Countdown Settings") {
            DatePicker("Target Date", selection: Binding(
                get: { config.targetDate },
                set: { newValue in
                    var c = config
                    c.targetDate = newValue
                    panel.encodeConfig(c)
                }
            ), displayedComponents: .date)

            TextField("Event Name", text: Binding(
                get: { config.eventName },
                set: { newValue in
                    var c = config
                    c.eventName = newValue
                    panel.encodeConfig(c)
                }
            ))
        }
    }

    private var notesConfigSection: some View {
        let config = panel.decodeConfig(NotesConfig.self) ?? NotesConfig()

        return Section("Notes") {
            TextField("Your note...", text: Binding(
                get: { config.noteText },
                set: { newValue in
                    var c = config
                    c.noteText = newValue
                    panel.encodeConfig(c)
                }
            ), axis: .vertical)
            .lineLimit(3...8)

            Stepper("Max Lines: \(config.maxLines)", value: Binding(
                get: { config.maxLines },
                set: { newValue in
                    var c = config
                    c.maxLines = newValue
                    panel.encodeConfig(c)
                }
            ), in: 1...12)
        }
    }

    private var quoteConfigSection: some View {
        let config = panel.decodeConfig(QuoteConfig.self) ?? QuoteConfig()

        return Section("Quote") {
            TextField("Quote text", text: Binding(
                get: { config.text },
                set: { newValue in
                    var c = config
                    c.text = newValue
                    panel.encodeConfig(c)
                }
            ), axis: .vertical)
            .lineLimit(2...6)

            TextField("Author", text: Binding(
                get: { config.author },
                set: { newValue in
                    var c = config
                    c.author = newValue
                    panel.encodeConfig(c)
                }
            ))
        }
    }

    private var habitsConfigSection: some View {
        let config = panel.decodeConfig(HabitsHeatmapConfig.self) ?? HabitsHeatmapConfig()

        return Section("Habits Heatmap") {
            TextField("Habit Name", text: Binding(
                get: { config.habitName },
                set: { newValue in
                    var c = config
                    c.habitName = newValue
                    panel.encodeConfig(c)
                }
            ))

            Stepper("Weeks: \(config.weeksToShow)", value: Binding(
                get: { config.weeksToShow },
                set: { newValue in
                    var c = config
                    c.weeksToShow = newValue
                    panel.encodeConfig(c)
                }
            ), in: 4...20)
        }
    }

    private var monthlyCalendarConfigSection: some View {
        let config = panel.decodeConfig(MonthlyCalendarConfig.self) ?? MonthlyCalendarConfig()

        return Section("Monthly Calendar") {
            Toggle("Highlight Today", isOn: Binding(
                get: { config.highlightToday },
                set: { newValue in
                    var c = config
                    c.highlightToday = newValue
                    panel.encodeConfig(c)
                }
            ))

            Toggle("Show Event Dots", isOn: Binding(
                get: { config.showEventDots },
                set: { newValue in
                    var c = config
                    c.showEventDots = newValue
                    panel.encodeConfig(c)
                }
            ))
        }
    }
}

// MARK: - Add Panel Sheet

struct AddPanelSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (PanelType) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(PanelType.allCases) { type in
                    Button {
                        onAdd(type)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: type.systemImage)
                                .foregroundStyle(.indigo)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.defaultTitle)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            if type.isPro {
                                Text("PRO")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.indigo)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Add Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditorView(
            template: WallpaperTemplate(name: "Preview", panels: [])
        )
        .environmentObject(SubscriptionManager())
    }
}
