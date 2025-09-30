//
//  DataModels.swift
//  TimeBoxApp
//
//  Core task data model only
//

import Foundation
import SwiftUI
import SwiftData

enum TaskType: String, CaseIterable, Codable {
    case sleep = "Sleep"
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
}

@Model
class TaskItem {
    var id: UUID
    var title: String
    var notes: String
    var isCompleted: Bool
    var createdDate: Date
    var scheduledDate: Date?
    var startTime: Date?
    var endTime: Date?
    var taskTypeRaw: String
    
    init(title: String, notes: String = "", scheduledDate: Date? = nil, 
         startTime: Date? = nil, endTime: Date? = nil, taskType: TaskType = .personal) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.isCompleted = false
        self.createdDate = Date()
        self.scheduledDate = scheduledDate
        self.startTime = startTime
        self.endTime = endTime
        self.taskTypeRaw = taskType.rawValue
    }
    
    var taskType: TaskType {
        get { TaskType(rawValue: taskTypeRaw) ?? .personal }
        set { taskTypeRaw = newValue.rawValue }
    }
    
    var duration: TimeInterval {
        guard let start = startTime, let end = endTime else { return 3600 }
        return end.timeIntervalSince(start)
    }
    
    var hasScheduledTime: Bool {
        startTime != nil && endTime != nil
    }
    
    var displayColor: Color {
        switch taskType {
        case .sleep: return .indigo
        case .work: return .blue
        case .personal: return .green
        case .health: return .orange
        }
    }
}

// Simple templates for quick task creation
struct TaskTemplate: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let defaultDuration: TimeInterval
    let taskType: TaskType
    let icon: String
    let color: Color
    
    static let defaultTemplates: [TaskTemplate] = [
        TaskTemplate(name: "Sleep", category: "Sleep", defaultDuration: 8*3600, taskType: .sleep, icon: "moon.zzz.fill", color: .indigo),
        TaskTemplate(name: "Work", category: "Work", defaultDuration: 8*3600, taskType: .work, icon: "briefcase.fill", color: .blue),
        TaskTemplate(name: "Meeting", category: "Work", defaultDuration: 3600, taskType: .work, icon: "person.2.fill", color: .blue),
        TaskTemplate(name: "Study", category: "School", defaultDuration: 2*3600, taskType: .personal, icon: "book.fill", color: .green),
        TaskTemplate(name: "Exercise", category: "Health", defaultDuration: 45*60, taskType: .health, icon: "figure.run", color: .orange),
        TaskTemplate(name: "Reading", category: "Personal", defaultDuration: 30*60, taskType: .personal, icon: "book.closed.fill", color: .purple),
    ]
}
