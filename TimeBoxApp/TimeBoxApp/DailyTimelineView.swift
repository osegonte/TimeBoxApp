//
//  DailyTimelineView.swift
//  TimeBoxApp
//
//  Fixed: Use NativeSchedulerSheet for task editing from calendar
//

import SwiftUI
import SwiftData

struct DailyTimelineView: View {
    let selectedDate: Date
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingSleepEditor = false
    @State private var showingTaskCreator = false
    @State private var selectedHour = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                // Header
                HStack {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text(selectedDate, format: .dateTime.day())
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Text(selectedDate, format: .dateTime.weekday(.wide))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(action: themeManager.toggleTheme) {
                        Image(systemName: themeManager.isDarkMode ? "sun.max" : "moon")
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                }
                .padding()
                
                // Timeline with interactions
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            TimelineHourView(
                                hour: hour,
                                selectedDate: selectedDate,
                                onSleepTap: {
                                    showingSleepEditor = true
                                },
                                onEmptyLongPress: {
                                    selectedHour = hour
                                    showingTaskCreator = true
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .background(themeManager.backgroundColor)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSleepEditor) {
            CompactSleepEditor(selectedDate: selectedDate)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTaskCreator) {
            TaskCreatorSheet(selectedDate: selectedDate, selectedHour: selectedHour)
        }
        .onAppear {
            taskManager.objectWillChange.send()
        }
    }
}

struct TimelineHourView: View {
    let hour: Int
    let selectedDate: Date
    let onSleepTap: () -> Void
    let onEmptyLongPress: () -> Void
    
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingTaskEditor = false
    @State private var selectedTask: TaskItem?
    
    private var hourString: String {
        String(format: "%02d:00", hour)
    }
    
    private var tasksForThisHour: [TaskItem] {
        taskManager.getTasksForTimeSlot(date: selectedDate, hour: hour)
    }
    
    private var sleepSchedule: SleepScheduleItem? {
        taskManager.getSleepScheduleForDate(selectedDate)
    }
    
    private var isSleepTime: Bool {
        guard let sleep = sleepSchedule else { return false }
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: sleep.startTime)
        let endHour = calendar.component(.hour, from: sleep.endTime)
        
        if startHour > endHour {
            return hour >= startHour || hour < endHour
        } else {
            return hour >= startHour && hour < endHour
        }
    }
    
    private let baseHourHeight: CGFloat = 60
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(hourString)
                .font(.caption)
                .foregroundColor(themeManager.secondaryTextColor)
                .frame(width: 50, alignment: .trailing)
                .padding(.top, 8)
            
            VStack(spacing: 4) {
                if isSleepTime {
                    // Tappable sleep block
                    SleepBlockView(
                        hour: hour,
                        sleepSchedule: sleepSchedule
                    )
                    .frame(height: baseHourHeight)
                    .onTapGesture {
                        onSleepTap()
                    }
                } else if !tasksForThisHour.isEmpty {
                    // Tappable task blocks
                    let taskHeight = tasksForThisHour.count > 1 ? 
                        baseHourHeight * CGFloat(tasksForThisHour.count) : baseHourHeight
                    
                    VStack(spacing: 2) {
                        ForEach(tasksForThisHour) { task in
                            TaskBlockView(
                                task: task,
                                hour: hour
                            )
                            .onTapGesture {
                                selectedTask = task
                                showingTaskEditor = true
                            }
                        }
                    }
                    .frame(height: taskHeight)
                } else {
                    // Empty slot with long press to create
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: baseHourHeight)
                        .overlay(
                            Rectangle()
                                .stroke(themeManager.secondaryTextColor.opacity(0.15), lineWidth: 0.5)
                        )
                        .onLongPressGesture {
                            onEmptyLongPress()
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .sheet(isPresented: $showingTaskEditor) {
            // FIXED: Use the same NativeSchedulerSheet that works in TasksView
            if let task = selectedTask {
                NativeSchedulerSheet(task: task)
                    .presentationDetents([.height(400)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.regularMaterial)
            }
        }
    }
}

struct CompactSleepEditor: View {
    let selectedDate: Date
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var sleepTime = Date()
    @State private var wakeTime = Date()
    @State private var duration: Double = 8.0
    @State private var editingMode: EditMode = .sleepTime
    
    enum EditMode {
        case sleepTime, wakeTime, duration
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep Schedule")
                        .font(.headline)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Text(selectedDate, format: .dateTime.weekday(.wide).month().day())
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Spacer()
                
                Button("Done") {
                    saveSleepSchedule()
                }
                .foregroundColor(.blue)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Sleep controls with green theme
            VStack(spacing: 16) {
                // Sleep time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sleep Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    DatePicker("", selection: $sleepTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: sleepTime) { _, newValue in
                            if editingMode == .sleepTime {
                                updateWakeTimeFromSleep()
                            }
                        }
                }
                .onTapGesture {
                    editingMode = .sleepTime
                }
                
                // Wake time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Wake Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .onChange(of: wakeTime) { _, newValue in
                            if editingMode == .wakeTime {
                                updateDurationFromTimes()
                            }
                        }
                }
                .onTapGesture {
                    editingMode = .wakeTime
                }
                
                // Duration slider
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration: \(String(format: "%.1f", duration)) hours")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    Slider(value: $duration, in: 4.0...12.0, step: 0.5)
                        .accentColor(.green)
                        .onChange(of: duration) { _, newValue in
                            if editingMode == .duration {
                                updateWakeTimeFromDuration()
                            }
                        }
                        .onTapGesture {
                            editingMode = .duration
                        }
                }
                
                // Summary
                VStack(spacing: 8) {
                    Text("Sleep Schedule")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("\(sleepTime, format: .dateTime.hour().minute()) - \(wakeTime, format: .dateTime.hour().minute())")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.green.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(themeManager.backgroundColor)
        .onAppear {
            loadCurrentSleepSchedule()
        }
    }
    
    private func loadCurrentSleepSchedule() {
        if let sleep = taskManager.getSleepScheduleForSpecificDate(selectedDate) {
            sleepTime = sleep.startTime
            wakeTime = sleep.endTime
            duration = sleep.duration / 3600
        } else {
            let calendar = Calendar.current
            sleepTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: selectedDate) ?? Date()
            wakeTime = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: selectedDate.addingTimeInterval(24*3600)) ?? Date()
            duration = 8.0
        }
    }
    
    private func updateWakeTimeFromSleep() {
        wakeTime = sleepTime.addingTimeInterval(duration * 3600)
    }
    
    private func updateWakeTimeFromDuration() {
        wakeTime = sleepTime.addingTimeInterval(duration * 3600)
    }
    
    private func updateDurationFromTimes() {
        let timeDiff = wakeTime.timeIntervalSince(sleepTime)
        duration = timeDiff > 0 ? timeDiff / 3600 : (timeDiff + 24*3600) / 3600
    }
    
    private func saveSleepSchedule() {
        taskManager.updateSleepScheduleForSpecificDate(selectedDate, sleepTime: sleepTime, wakeTime: wakeTime, duration: duration)
        dismiss()
    }
}

struct TaskCreatorSheet: View {
    let selectedDate: Date
    let selectedHour: Int
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var taskTitle = ""
    @State private var taskNotes = ""
    @State private var selectedTime = Date()
    @State private var duration: Double = 60
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $taskTitle)
                    TextField("Notes (optional)", text: $taskNotes, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section("Schedule") {
                    DatePicker("Start Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    
                    Picker("Duration", selection: $duration) {
                        Text("15 min").tag(15.0)
                        Text("30 min").tag(30.0)
                        Text("1 hour").tag(60.0)
                        Text("1.5 hours").tag(90.0)
                        Text("2 hours").tag(120.0)
                        Text("3 hours").tag(180.0)
                    }
                }
                
                Section {
                    let endTime = selectedTime.addingTimeInterval(duration * 60)
                    HStack {
                        Text("Scheduled Time")
                        Spacer()
                        Text("\(selectedTime, format: .dateTime.hour().minute()) - \(endTime, format: .dateTime.hour().minute())")
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
            }
            .navigationTitle("Create Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(taskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            setupDefaultTime()
        }
    }
    
    private func setupDefaultTime() {
        let calendar = Calendar.current
        selectedTime = calendar.date(bySettingHour: selectedHour, minute: 0, second: 0, of: selectedDate) ?? Date()
    }
    
    private func createTask() {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        guard let startTime = calendar.date(from: combinedComponents) else { return }
        let endTime = startTime.addingTimeInterval(duration * 60)
        
        taskManager.addTask(
            title: taskTitle.trimmingCharacters(in: .whitespaces),
            notes: taskNotes.trimmingCharacters(in: .whitespaces),
            scheduledDate: selectedDate,
            startTime: startTime,
            endTime: endTime,
            taskType: .personal
        )
        
        dismiss()
    }
}

struct TaskBlockView: View {
    let task: TaskItem
    let hour: Int
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var isStartingHour: Bool {
        guard let startTime = task.startTime else { return false }
        return Calendar.current.component(.hour, from: startTime) == hour
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(task.displayColor)
                .frame(width: 4)
                .cornerRadius(2)
            
            VStack(alignment: .leading, spacing: 4) {
                if isStartingHour {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.primaryTextColor)
                        .lineLimit(2)
                    
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .lineLimit(1)
                    }
                    
                    if let start = task.startTime, let end = task.endTime {
                        Text("\(start, format: .dateTime.hour().minute()) - \(end, format: .dateTime.hour().minute())")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                } else {
                    HStack {
                        Rectangle()
                            .fill(task.displayColor.opacity(0.3))
                            .frame(height: 2)
                            .cornerRadius(1)
                        
                        Text(task.title)
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, isStartingHour ? 12 : 6)
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(8)
    }
}

struct SleepBlockView: View {
    let hour: Int
    let sleepSchedule: SleepScheduleItem?
    @EnvironmentObject private var themeManager: ThemeManager
    
    private var isSleepStartHour: Bool {
        guard let sleep = sleepSchedule else { return false }
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: sleep.startTime)
        return hour == startHour
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.green.opacity(0.8))
                .frame(width: 4)
                .cornerRadius(2)
            
            if isSleepStartHour {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(Color.green)
                            .font(.caption)
                        
                        Text("Sleep")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.primaryTextColor)
                    }
                    
                    if let sleep = sleepSchedule {
                        Text("\(sleep.startTime, format: .dateTime.hour().minute()) - \(sleep.endTime, format: .dateTime.hour().minute())")
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        let hours = sleep.duration / 3600
                        Text("\(String(format: "%.1f", hours)) hours")
                            .font(.caption2)
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            } else {
                HStack {
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(height: 2)
                        .cornerRadius(1)
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, isSleepStartHour ? 12 : 6)
        .background(Color.green.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    DailyTimelineView(selectedDate: Date())
        .environmentObject(TaskManager(context: ModelContext(ModelContainer.preview)))
        .environmentObject(ThemeManager())
        .modelContainer(ModelContainer.preview)
}
