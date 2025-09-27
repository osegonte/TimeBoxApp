//
//  Task.swift
//  TimeBoxApp
//
//  Fixed color handling
//

import Foundation
import SwiftUI

struct Task: Identifiable, Codable, Equatable {
    let id = UUID()
    var title: String
    var notes: String = ""
    var isCompleted: Bool = false
    var createdDate: Date = Date()
    
    // Enhanced scheduling
    var scheduledDate: Date?
    var startTime: Date?
    var endTime: Date?
    var isAllDay: Bool = false
    var taskType: TaskType = .personal
    
    // Convenience computed properties
    var duration: TimeInterval {
        guard let start = startTime, let end = endTime else { return 3600 }
        return end.timeIntervalSince(start)
    }
    
    var hasScheduledTime: Bool {
        startTime != nil && endTime != nil
    }
    
    var displayColor: Color {
        switch taskType {
        case .sleep: return .purple
        case .work: return .blue
        case .personal: return .green
        case .health: return .orange
        }
    }
    
    init(title: String, notes: String = "", scheduledDate: Date? = nil, 
         startTime: Date? = nil, endTime: Date? = nil, taskType: TaskType = .personal) {
        self.title = title
        self.notes = notes
        self.scheduledDate = scheduledDate
        self.startTime = startTime
        self.endTime = endTime
        self.taskType = taskType
    }
}

enum TaskType: String, CaseIterable, Codable {
    case sleep = "Sleep"
    case work = "Work"
    case personal = "Personal"
    case health = "Health"
}
