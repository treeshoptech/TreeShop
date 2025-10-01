import SwiftUI
import SwiftData

struct TIME_TRACKER_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TIME_ENTRY.startTime, order: .reverse) private var timeEntries: [TIME_ENTRY]

    @State private var showingStartTask = false
    @State private var activeEntry: TIME_ENTRY?

    var activeTimeEntry: TIME_ENTRY? {
        timeEntries.first { !$0.isComplete }
    }

    var todaysEntries: [TIME_ENTRY] {
        timeEntries.filter { entry in
            Calendar.current.isDateInToday(entry.startTime)
        }
    }

    var todayTotalHours: Double {
        todaysEntries.reduce(0.0) { $0 + $1.duration }
    }

    var todayBillableHours: Double {
        todaysEntries.filter { $0.isBillable }.reduce(0.0) { $0 + $1.duration }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        // Active timer
                        if let active = activeTimeEntry {
                            ACTIVE_TIMER_CARD(entry: active)
                        }

                        // Today's summary
                        HStack(spacing: APP_THEME.SPACING_MD) {
                            STAT_CARD(
                                label: "Total Hours",
                                value: String(format: "%.1f", todayTotalHours),
                                change: nil,
                                color: APP_THEME.PRIMARY
                            )

                            STAT_CARD(
                                label: "Billable Hours",
                                value: String(format: "%.1f", todayBillableHours),
                                change: nil,
                                color: APP_THEME.SUCCESS
                            )
                        }

                        // Today's entries
                        if !todaysEntries.isEmpty {
                            VStack(alignment: .leading, spacing: APP_THEME.SPACING_MD) {
                                Text("Today's Tasks")
                                    .font(.headline)
                                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                                ForEach(todaysEntries) { entry in
                                    TIME_ENTRY_CARD(entry: entry)
                                }
                            }
                        } else {
                            EMPTY_STATE(
                                icon: "clock.fill",
                                title: "No Time Entries Today",
                                message: "Start tracking time for your tasks",
                                actionTitle: "Start Task",
                                action: { showingStartTask = true }
                            )
                        }
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Time Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingStartTask = true }) {
                        Image(systemName: activeTimeEntry == nil ? "play.circle.fill" : "plus.circle.fill")
                            .foregroundColor(APP_THEME.PRIMARY)
                    }
                }
            }
            .sheet(isPresented: $showingStartTask) {
                START_TASK_VIEW()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ACTIVE TIMER CARD

struct ACTIVE_TIMER_CARD: View {
    @Environment(\.modelContext) private var modelContext
    let entry: TIME_ENTRY

    @State private var currentDuration: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: APP_THEME.SPACING_MD) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE TASK")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(APP_THEME.SUCCESS)

                    Text(entry.taskDescription)
                        .font(.headline)
                        .foregroundColor(APP_THEME.TEXT_PRIMARY)

                    Text(entry.taskCategory)
                        .font(.subheadline)
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }

                Spacer()

                if entry.isPaused {
                    Image(systemName: "pause.circle.fill")
                        .font(.title)
                        .foregroundColor(APP_THEME.WARNING)
                }
            }

            // Timer display
            Text(formatDuration(currentDuration))
                .font(.system(size: 48, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(APP_THEME.PRIMARY)

            // Controls
            HStack(spacing: APP_THEME.SPACING_MD) {
                if entry.isPaused {
                    Button(action: { resumeTask() }) {
                        Label("Resume", systemImage: "play.fill")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(APP_THEME.SPACING_MD)
                            .background(APP_THEME.SUCCESS)
                            .cornerRadius(APP_THEME.RADIUS_MD)
                    }
                } else {
                    Button(action: { pauseTask() }) {
                        Label("Pause", systemImage: "pause.fill")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(APP_THEME.SPACING_MD)
                            .background(APP_THEME.WARNING)
                            .cornerRadius(APP_THEME.RADIUS_MD)
                    }
                }

                Button(action: { completeTask() }) {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(APP_THEME.SPACING_MD)
                        .background(APP_THEME.PRIMARY)
                        .cornerRadius(APP_THEME.RADIUS_MD)
                }
            }
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.SUCCESS.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: APP_THEME.RADIUS_MD)
                .stroke(APP_THEME.SUCCESS, lineWidth: 2)
        )
        .cornerRadius(APP_THEME.RADIUS_MD)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if !entry.isPaused {
                currentDuration = Date().timeIntervalSince(entry.startTime) - (entry.totalPausedTime * 3600)
            }
        }
    }

    func pauseTask() {
        entry.pause()
    }

    func resumeTask() {
        entry.resume()
    }

    func completeTask() {
        entry.complete()
        do {
            try modelContext.save()
        } catch {
            print("Error completing task: \(error)")
        }
        timer?.invalidate()
    }

    func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - TIME ENTRY CARD

struct TIME_ENTRY_CARD: View {
    let entry: TIME_ENTRY

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.taskDescription)
                    .font(.body)
                    .foregroundColor(APP_THEME.TEXT_PRIMARY)

                HStack(spacing: APP_THEME.SPACING_SM) {
                    Text(entry.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)

                    Text("•")
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)

                    Text("\(String(format: "%.1f", entry.duration))h")
                        .font(.caption)
                        .foregroundColor(APP_THEME.TEXT_SECONDARY)

                    if entry.isBillable {
                        STATUS_BADGE(text: "Billable", color: APP_THEME.SUCCESS, size: .SMALL)
                    }
                }
            }

            Spacer()

            if let pph = entry.pphAchieved {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(pph))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(APP_THEME.PRIMARY)

                    Text("PpH")
                        .font(.caption2)
                        .foregroundColor(APP_THEME.TEXT_TERTIARY)
                }
            }
        }
        .padding(APP_THEME.SPACING_MD)
        .background(APP_THEME.BG_SECONDARY)
        .cornerRadius(APP_THEME.RADIUS_MD)
    }
}

// MARK: - START TASK VIEW

struct START_TASK_VIEW: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var taskType: TASK_TYPE = .LINE_ITEM
    @State private var selectedSupport: SUPPORT_TASK = .TRANSPORT
    @State private var taskDescription = ""

    var body: some View {
        NavigationStack {
            ZStack {
                APP_THEME.BG_PRIMARY.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: APP_THEME.SPACING_LG) {
                        FORM_SECTION(title: "Task Type", icon: "list.bullet.circle.fill", color: APP_THEME.INFO) {
                            Picker("Type", selection: $taskType) {
                                ForEach(TASK_TYPE.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)

                            if taskType == .SUPPORT {
                                Picker("Support Task", selection: $selectedSupport) {
                                    ForEach(SUPPORT_TASK.allCases, id: \.self) { task in
                                        HStack {
                                            Image(systemName: task.icon)
                                            Text(task.rawValue)
                                        }.tag(task)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(APP_THEME.SPACING_MD)
                                .background(APP_THEME.BG_TERTIARY)
                                .cornerRadius(APP_THEME.RADIUS_SM)
                            }
                        }

                        FORM_SECTION(title: "Description", icon: "text.alignleft", color: APP_THEME.PRIMARY) {
                            TextEditor(text: $taskDescription)
                                .frame(height: 100)
                                .padding(APP_THEME.SPACING_SM)
                                .background(APP_THEME.BG_TERTIARY)
                                .cornerRadius(APP_THEME.RADIUS_SM)
                                .foregroundColor(APP_THEME.TEXT_PRIMARY)
                        }

                        ACTION_BUTTON(
                            title: "Start Timer",
                            icon: "play.circle.fill",
                            color: APP_THEME.SUCCESS
                        ) {
                            startTask()
                        }
                        .disabled(taskDescription.isEmpty && taskType == .LINE_ITEM)
                    }
                    .padding(APP_THEME.SPACING_MD)
                }
            }
            .navigationTitle("Start Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(APP_THEME.TEXT_SECONDARY)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    func startTask() {
        let category = taskType == .SUPPORT ? selectedSupport.rawValue : "Line Item Task"
        let description = taskDescription.isEmpty ? category : taskDescription

        let newEntry = TIME_ENTRY(
            taskType: taskType,
            taskCategory: category,
            taskDescription: description,
            isBillable: taskType.isBillable
        )

        modelContext.insert(newEntry)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error starting task: \(error)")
        }
    }
}
