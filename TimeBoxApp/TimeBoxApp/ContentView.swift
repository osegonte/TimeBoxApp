//
//  ContentView.swift
//  TimeBoxApp
//
//  Fixed TaskManager context issue
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        TabView {
            TasksView()
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Tasks")
                }
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
        }
        .environmentObject(TaskManager(context: context))
        .environmentObject(themeManager)
    }
}

extension ModelContainer {
    static var preview: ModelContainer {
        do {
            let container = try ModelContainer(for: TaskItem.self, SleepScheduleItem.self)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.preview)
}
