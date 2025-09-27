//
//  TaskManager.swift
//  TimeBoxApp
//
//  Fixed with getAllTasks method properly placed
//

import SwiftUI
import SwiftData

@MainActor
class TaskManager: ObservableObject {
    private var context: ModelContext
    @Published var tasks: [TaskItem] = []
    
    init(context: ModelContext) {
        self.context = context
        loadTasks()
    }
    
    func updateContext(_ newContext: ModelContext) {
        self.context = newContext
        loadTasks()
    }
    
    private func loadTasks() {
        let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.createdDate)])
        tasks = (try? context.fetch(descriptor)) ?? []
    }
    
    func addTask(title: String, notes: String = "", scheduledDate: Date? = nil, startTime: Date? = nil, endTime: Date? = nil, taskType: TaskType = .personal) {
        let task = TaskItem(
            title: title,
            notes: notes,
            scheduledDate: scheduledDate,
            startTime: startTime,
            endTime: endTime,
            taskType: taskType
        )
        
        context.insert(task)
        saveContext()
        loadTasks()
    }
    
    func updateTask(_ task: TaskItem) {
        saveContext()
        loadTasks()
        objectWillChange.send()
    }
    
    func deleteTask(_ task: TaskItem) {
        context.delete(task)
        saveContext()
        loadTasks()
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        saveContext()
        loadTasks()
        objectWillChange.send()
    }
    
    func getTodaysTasks() -> [TaskItem] {
        let calendar = Calendar.current
        let today = Date()
        
        let todaysScheduledTasks = tasks.filter { task in
            if let scheduledDate = task.scheduledDate, calendar.isDate(scheduledDate, inSameDayAs: today) {
                return true
            }
            if let startTime = task.startTime, calendar.isDate(startTime, inSameDayAs: today) {
                return true
            }
            return false
        }
        
        return todaysScheduledTasks.sorted { task1, task2 in
            if let start1 = task1.startTime, let start2 = task2.startTime {
                return start1 < start2
            }
            return task1.createdDate < task2.createdDate
        }
    }
    
    // Get all tasks (including scheduled ones) for to-do list
    func getAllTasks() -> [TaskItem] {
        return tasks.sorted { $0.createdDate < $1.createdDate }
    }
    
    func getUnscheduledTasks() -> [TaskItem] {
        return tasks.filter { task in
            task.scheduledDate == nil && task.startTime == nil
        }.sorted { $0.createdDate < $1.createdDate }
    }
    
    func getTasksForDate(_ date: Date) -> [TaskItem] {
        let calendar = Calendar.current
        return tasks.filter { task in
            if let scheduledDate = task.scheduledDate, calendar.isDate(scheduledDate, inSameDayAs: date) {
                return true
            }
            if let startTime = task.startTime, calendar.isDate(startTime, inSameDayAs: date) {
                return true
            }
            return false
        }.sorted { task1, task2 in
            if let start1 = task1.startTime, let start2 = task2.startTime {
                return start1 < start2
            }
            return task1.createdDate < task2.createdDate
        }
    }
    
    func getTasksForTimeSlot(date: Date, hour: Int) -> [TaskItem] {
        let calendar = Calendar.current
        return getTasksForDate(date).filter { task in
            guard let startTime = task.startTime, let endTime = task.endTime else { return false }
            let startHour = calendar.component(.hour, from: startTime)
            let endHour = calendar.component(.hour, from: endTime)
            
            if startHour <= hour && hour < endHour {
                return true
            }
            if startHour == hour {
                return true
            }
            return false
        }
    }
    
    func getTodaysProgress() -> (completed: Int, total: Int, percentage: Double) {
        let todaysTasks = getTodaysTasks()
        let completed = todaysTasks.filter(\.isCompleted).count
        let total = todaysTasks.count
        let percentage = total > 0 ? Double(completed) / Double(total) : 0.0
        return (completed, total, percentage)
    }
    
    func getSleepScheduleForDate(_ date: Date) -> SleepScheduleItem? {
        if let specificSchedule = getSleepScheduleForSpecificDate(date) {
            return specificSchedule
        }
        return createDefaultSleepSchedule(for: date)
    }
    
    func updateSleepSchedule(for date: Date, startHour: Int, duration: Double) {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: date) ?? date
        let endTime = startTime.addingTimeInterval(duration * 3600)
        
        let descriptor = FetchDescriptor<SleepScheduleItem>()
        let existingSleep = (try? context.fetch(descriptor)) ?? []
        
        if let existing = existingSleep.first {
            existing.startTime = startTime
            existing.endTime = endTime
        } else {
            let sleepItem = SleepScheduleItem(
                date: date,
                startTime: startTime,
                endTime: endTime
            )
            context.insert(sleepItem)
        }
        
        saveContext()
    }
    
    func getSleepScheduleForSpecificDate(_ date: Date) -> SleepScheduleItem? {
        let calendar = Calendar.current
        let descriptor = FetchDescriptor<SleepScheduleItem>()
        let sleepItems = (try? context.fetch(descriptor)) ?? []
        
        return sleepItems.first { item in
            calendar.isDate(item.date, inSameDayAs: date)
        }
    }
    
    func updateSleepScheduleForSpecificDate(_ date: Date, sleepTime: Date, wakeTime: Date, duration: Double) {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: calendar.component(.hour, from: sleepTime), 
                                     minute: calendar.component(.minute, from: sleepTime), 
                                     second: 0, of: date) ?? sleepTime
        let endTime = startTime.addingTimeInterval(duration * 3600)
        
        if let existing = getSleepScheduleForSpecificDate(date) {
            existing.startTime = startTime
            existing.endTime = endTime
        } else {
            let sleepItem = SleepScheduleItem(
                date: date,
                startTime: startTime,
                endTime: endTime
            )
            context.insert(sleepItem)
        }
        
        saveContext()
    }
    
    private func createDefaultSleepSchedule(for date: Date) -> SleepScheduleItem {
        let calendar = Calendar.current
        let startTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: date) ?? date
        let endTime = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: date.addingTimeInterval(24*3600)) ?? date
        
        return SleepScheduleItem(
            date: date,
            startTime: startTime,
            endTime: endTime
        )
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
