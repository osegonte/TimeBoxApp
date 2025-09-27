//
//  DataModels.swift
//  TimeBoxApp
//
//  SwiftData models - no duplicate TaskType
//

import Foundation
import SwiftUI
import SwiftData

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

@Model
class SleepScheduleItem {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
    
    init(date: Date, startTime: Date, endTime: Date) {
        self.id = UUID()
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
    }
}
