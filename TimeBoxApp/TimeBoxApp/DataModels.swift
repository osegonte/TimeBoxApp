//
//  DataModels.swift
//  TimeBoxApp
//
//  FIXED: Removed duplicate TaskTemplate declarations
//

import Foundation
import SwiftUI
import SwiftData

// MIGRATION: Schema versioning
enum SchemaVersion {
    case v1_0
    case v1_1 // Future version for when we add new fields
    
    static let current: SchemaVersion = .v1_0
}

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
    
    // TEMPLATE: Add template support
    var isFromTemplate: Bool = false
    var templateName: String = ""
    
    // MIGRATION: Version tracking
    var schemaVersion: String = SchemaVersion.current.rawValue
    
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
        self.schemaVersion = SchemaVersion.current.rawValue
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
    
    // MIGRATION: Update schema version
    func updateToCurrentSchema() {
        self.schemaVersion = SchemaVersion.current.rawValue
    }
}

@Model
class SleepScheduleItem {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
    
    // MIGRATION: Version tracking
    var schemaVersion: String = SchemaVersion.current.rawValue
    
    init(date: Date, startTime: Date, endTime: Date) {
        self.id = UUID()
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.duration = endTime.timeIntervalSince(startTime)
        self.schemaVersion = SchemaVersion.current.rawValue
    }
    
    // MIGRATION: Update schema version
    func updateToCurrentSchema() {
        self.schemaVersion = SchemaVersion.current.rawValue
    }
}

// TEMPLATE: Simple template structure (no SwiftData conflicts)
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

// Keep existing migration components
class DataMigrationManager {
    static let shared = DataMigrationManager()
    
    private init() {}
    
    func performMigrationIfNeeded(context: ModelContext) {
        do {
            let taskDescriptor = FetchDescriptor<TaskItem>()
            let tasks = try context.fetch(taskDescriptor)
            
            let sleepDescriptor = FetchDescriptor<SleepScheduleItem>()
            let sleepItems = try context.fetch(sleepDescriptor)
            
            var needsSave = false
            
            for task in tasks {
                if task.schemaVersion != SchemaVersion.current.rawValue {
                    migrateTask(task)
                    needsSave = true
                }
            }
            
            for sleepItem in sleepItems {
                if sleepItem.schemaVersion != SchemaVersion.current.rawValue {
                    migrateSleepItem(sleepItem)
                    needsSave = true
                }
            }
            
            if needsSave {
                try context.save()
                print("Migration completed successfully")
            }
            
        } catch {
            print("Migration failed: \(error)")
        }
    }
    
    private func migrateTask(_ task: TaskItem) {
        task.updateToCurrentSchema()
    }
    
    private func migrateSleepItem(_ sleepItem: SleepScheduleItem) {
        sleepItem.updateToCurrentSchema()
    }
    
    func createBackup(context: ModelContext) throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsPath.appendingPathComponent("timeboxapp_backup_\(Date().timeIntervalSince1970).json")
        
        let taskDescriptor = FetchDescriptor<TaskItem>()
        let tasks = try context.fetch(taskDescriptor)
        
        let sleepDescriptor = FetchDescriptor<SleepScheduleItem>()
        let sleepItems = try context.fetch(sleepDescriptor)
        
        let backupData = BackupData(
            tasks: tasks.map { TaskBackup(from: $0) },
            sleepItems: sleepItems.map { SleepBackup(from: $0) },
            backupDate: Date(),
            schemaVersion: SchemaVersion.current.rawValue
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(backupData)
        
        try jsonData.write(to: backupURL)
        print("Backup created at: \(backupURL)")
    }
}

struct BackupData: Codable {
    let tasks: [TaskBackup]
    let sleepItems: [SleepBackup]
    let backupDate: Date
    let schemaVersion: String
}

struct TaskBackup: Codable {
    let id: String
    let title: String
    let notes: String
    let isCompleted: Bool
    let createdDate: Date
    let scheduledDate: Date?
    let startTime: Date?
    let endTime: Date?
    let taskTypeRaw: String
    let schemaVersion: String
    
    init(from task: TaskItem) {
        self.id = task.id.uuidString
        self.title = task.title
        self.notes = task.notes
        self.isCompleted = task.isCompleted
        self.createdDate = task.createdDate
        self.scheduledDate = task.scheduledDate
        self.startTime = task.startTime
        self.endTime = task.endTime
        self.taskTypeRaw = task.taskTypeRaw
        self.schemaVersion = task.schemaVersion
    }
}

struct SleepBackup: Codable {
    let id: String
    let date: Date
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let schemaVersion: String
    
    init(from sleepItem: SleepScheduleItem) {
        self.id = sleepItem.id.uuidString
        self.date = sleepItem.date
        self.startTime = sleepItem.startTime
        self.endTime = sleepItem.endTime
        self.duration = sleepItem.duration
        self.schemaVersion = sleepItem.schemaVersion
    }
}

extension SchemaVersion {
    var rawValue: String {
        switch self {
        case .v1_0: return "v1_0"
        case .v1_1: return "v1_1"
        }
    }
}
