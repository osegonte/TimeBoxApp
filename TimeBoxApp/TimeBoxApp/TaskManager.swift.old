//
//  TaskManager.swift
//  TimeBoxApp
//
//  RESTORED: Working task queries
//

import SwiftUI
import SwiftData
import Foundation

@MainActor
class TaskManager: ObservableObject {
    private let modelContext: ModelContext
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    init(context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Task Management
    func addTask(title: String, notes: String = "", taskType: TaskType = .personal) {
        let task = TaskItem(
            title: title,
            notes: notes,
            taskType: taskType
        )
        
        modelContext.insert(task)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save task: \(error.localizedDescription)"
        }
    }
    
    func updateTask(_ task: TaskItem) {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }
    
    func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        updateTask(task)
    }
    
    // MARK: - Task Queries (RESTORED)
    func getAllTasks() -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch tasks: \(error.localizedDescription)"
            return []
        }
    }
    
    func getIncompleteTasks() -> [TaskItem] {
        // FIXED: Don't filter by date - get all incomplete tasks
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                !task.isCompleted
            },
            sortBy: [SortDescriptor(\.createdDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch incomplete tasks: \(error.localizedDescription)"
            return []
        }
    }
    
    func getCompletedTasks() -> [TaskItem] {
        // FIXED: Get today's completed tasks only
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.isCompleted && task.createdDate >= today && task.createdDate < tomorrow
            },
            sortBy: [SortDescriptor(\.createdDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch completed tasks: \(error.localizedDescription)"
            return []
        }
    }
    
    func getTasksForDate(_ date: Date) -> [TaskItem] {
        // FIXED: Simple approach - get all tasks and filter them
        let descriptor = FetchDescriptor<TaskItem>()
        
        do {
            let allTasks = try modelContext.fetch(descriptor)
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            return allTasks.filter { task in
                // Check if task has scheduled date for this day
                if let scheduledDate = task.scheduledDate {
                    return calendar.isDate(scheduledDate, inSameDayAs: date)
                }
                // Check if task has start time for this day
                if let startTime = task.startTime {
                    return calendar.isDate(startTime, inSameDayAs: date)
                }
                return false
            }
        } catch {
            errorMessage = "Failed to fetch tasks for date: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Progress Tracking
    func getTodaysProgress() -> (completed: Int, total: Int, percentage: Double) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let descriptor = FetchDescriptor<TaskItem>(
            predicate: #Predicate { task in
                task.createdDate >= today && task.createdDate < tomorrow
            }
        )
        
        do {
            let tasks = try modelContext.fetch(descriptor)
            let completed = tasks.filter { $0.isCompleted }.count
            let total = tasks.count
            let percentage = total > 0 ? Double(completed) / Double(total) : 0.0
            
            return (completed: completed, total: total, percentage: percentage)
        } catch {
            errorMessage = "Failed to calculate progress: \(error.localizedDescription)"
            return (completed: 0, total: 0, percentage: 0.0)
        }
    }
}
