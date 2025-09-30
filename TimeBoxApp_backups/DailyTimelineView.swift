//
//  DailyTimelineView.swift
//  TimeBoxApp
//
//  FIXED: Shows unscheduled tasks at top + hourly tasks
//

import SwiftUI
import SwiftData

struct DailyTimelineView: View {
    let selectedDate: Date
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTask: TaskItem?
    @State private var showingTaskEditor = false
    @State private var showingSleepEditor = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Date header
                VStack(spacing: 8) {
                    Text("\(Calendar.current.component(.day, from: selectedDate))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(selectedDate, format: .dateTime.weekday(.abbreviated))
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color.black)
                
                // UNSCHEDULED TASKS (no specific time)
                let unscheduledTasks = getUnscheduledTasksForDay()
                if !unscheduledTasks.isEmpty {
                    VStack(spacing: 8) {
                        Text("Tasks for Today")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 16)
                        
                        ForEach(unscheduledTasks) { task in
                            Button(action: { 
                                selectedTask = task
                                showingTaskEditor = true
                            }) {
                                UnscheduledTaskRow(task: task)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)
                }
                
                // Interactive hour blocks
                ForEach(0..<24, id: \.self) { hour in
                    InteractiveHourBlock(
                        hour: hour, 
                        date: selectedDate
                    ) { task in
                        selectedTask = task
                        showingTaskEditor = true
                    } onSleepTap: {
                        showingSleepEditor = true
                    }
                }
            }
        }
        .background(Color.black)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Calendar")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingTaskEditor) {
            if let task = selectedTask {
                NativeSchedulerSheet(task: task)
                    .presentationDetents([.height(400)])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.regularMaterial)
            }
        }
        .sheet(isPresented: $showingSleepEditor) {
            SimpleSleepEditor(date: selectedDate)
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
        }
    }
    
    private func getUnscheduledTasksForDay() -> [TaskItem] {
        return taskManager.getTasksForDate(selectedDate).filter { task in
            task.startTime == nil // Tasks without specific hour
        }
    }
}

struct UnscheduledTaskRow: View {
    let task: TaskItem
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(task.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryTextColor)
                
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                
                Text("Tap to schedule time")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Rectangle()
                .fill(task.displayColor)
                .frame(width: 4, height: 40)
                .cornerRadius(2)
        }
        .padding()
        .background(themeManager.cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct InteractiveHourBlock: View {
    let hour: Int
    let date: Date
    let onTaskTap: (TaskItem) -> Void
    let onSleepTap: () -> Void
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Hour label
            Text(String(format: "%02d:00", hour))
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, 16)
            
            // Content area
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 0.5)
                
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        if isSleepHour(hour) {
                            Button(action: onSleepTap) {
                                InteractiveSleepBlock(hour: hour, date: date)
                                    .frame(width: geometry.size.width - 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            let tasks = getTasksForHour(hour)
                            if !tasks.isEmpty {
                                let taskWidth = (geometry.size.width - 16) / CGFloat(tasks.count)
                                
                                HStack(spacing: 0) {
                                    ForEach(Array(tasks.enumerated()), id: \.offset) { index, task in
                                        Button(action: { onTaskTap(task) }) {
                                            InteractiveTaskBlock(task: task)
                                                .frame(width: taskWidth)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                }
                .frame(height: 60)
                .padding(.top, 8)
            }
        }
        .frame(height: 80)
        .padding(.horizontal)
    }
    
    private func isSleepHour(_ hour: Int) -> Bool {
        if let sleepSchedule = taskManager.getSleepScheduleForDate(date) {
            let calendar = Calendar.current
            let sleepHour = calendar.component(.hour, from: sleepSchedule.startTime)
            let wakeHour = calendar.component(.hour, from: sleepSchedule.endTime)
            
            if sleepHour > wakeHour {
                return hour >= sleepHour || hour < wakeHour
            } else {
                return hour >= sleepHour && hour < wakeHour
            }
        }
        return hour >= 22 || hour < 6
    }
    
    private func getTasksForHour(_ hour: Int) -> [TaskItem] {
        let calendar = Calendar.current
        return taskManager.getTasksForDate(date).filter { task in
            guard let startTime = task.startTime else { return false }
            return calendar.component(.hour, from: startTime) == hour
        }
    }
}

struct InteractiveSleepBlock: View {
    let hour: Int
    let date: Date
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "moon.zzz.fill")
                        .font(.subheadline)
                        .foregroundColor(.indigo)
                    
                    Text("Sleep")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.indigo)
                    
                    Spacer()
                }
                
                if let schedule = taskManager.getSleepScheduleForDate(date) {
                    let calendar = Calendar.current
                    let sleepHour = calendar.component(.hour, from: schedule.startTime)
                    let wakeHour = calendar.component(.hour, from: schedule.endTime)
                    
                    if hour == sleepHour {
                        let duration = schedule.duration / 3600
                        Text("\(duration, specifier: "%.1f")h (\(String(format: "%02d", sleepHour))-\(String(format: "%02d", wakeHour))) • tap to edit")
                            .font(.caption2)
                            .foregroundColor(.indigo.opacity(0.8))
                    } else {
                        Text("tap to edit")
                            .font(.caption2)
                            .foregroundColor(.indigo.opacity(0.8))
                    }
                } else if hour == 22 {
                    Text("8h (22-06) • tap to edit")
                        .font(.caption2)
                        .foregroundColor(.indigo.opacity(0.8))
                } else {
                    Text("tap to edit")
                        .font(.caption2)
                        .foregroundColor(.indigo.opacity(0.8))
                }
            }
            
            Rectangle()
                .fill(.indigo)
                .frame(width: 4)
                .cornerRadius(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(themeManager.cardBackgroundColor.opacity(0.3))
        .cornerRadius(12)
        .frame(height: 50)
    }
}

struct InteractiveTaskBlock: View {
    let task: TaskItem
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption2)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                if task.isCompleted {
                    Text("Completed")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer(minLength: 0)
            
            Rectangle()
                .fill(task.displayColor)
                .frame(width: 3)
                .cornerRadius(1.5)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(task.isCompleted ? themeManager.cardBackgroundColor.opacity(0.7) : themeManager.cardBackgroundColor)
        .cornerRadius(8)
        .frame(height: 50)
        .opacity(task.isCompleted ? 0.8 : 1.0)
    }
}

struct SimpleSleepEditor: View {
    let date: Date
    @EnvironmentObject private var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var sleepTime = Date()
    @State private var wakeTime = Date()
    @State private var selectedDuration: Double = 8.0
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("Sleep")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Save") {
                    saveSleepSchedule()
                }
                .foregroundColor(.blue)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("Sleep")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $sleepTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .scaleEffect(0.9)
                        .onChange(of: sleepTime) { _, _ in
                            updateDuration()
                        }
                }
                
                Text("→")
                    .foregroundColor(.secondary)
                
                VStack(spacing: 4) {
                    Text("Wake")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .scaleEffect(0.9)
                        .onChange(of: wakeTime) { _, _ in
                            updateDuration()
                        }
                }
            }
            
            Text("\(selectedDuration, specifier: "%.1f")h")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            
            Text(date, format: .dateTime.month().day())
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
        }
        .onAppear {
            loadCurrentSchedule()
        }
    }
    
    private func loadCurrentSchedule() {
        let calendar = Calendar.current
        
        if let schedule = taskManager.getSleepScheduleForDate(date) {
            sleepTime = schedule.startTime
            wakeTime = schedule.endTime
        } else {
            sleepTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: date) ?? Date()
            wakeTime = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: date.addingTimeInterval(24*3600)) ?? Date()
        }
        
        updateDuration()
    }
    
    private func updateDuration() {
        var duration = wakeTime.timeIntervalSince(sleepTime)
        if duration < 0 {
            duration += 24 * 3600
        }
        selectedDuration = duration / 3600
    }
    
    private func saveSleepSchedule() {
        taskManager.updateSleepSchedule(for: date, sleepTime: sleepTime, wakeTime: wakeTime)
        dismiss()
    }
}

#Preview {
    DailyTimelineView(selectedDate: Date())
        .environmentObject(TaskManager(context: ModelContext(ModelContainer.preview)))
        .environmentObject(ThemeManager())
}
