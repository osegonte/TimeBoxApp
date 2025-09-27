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
    @StateObject private var taskManager: TaskManager
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        // We'll set this up properly in onAppear since we need the context
        self._taskManager = StateObject(wrappedValue: TaskManager(context: ModelContext(ModelContainer.preview)))
    }
    
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
        .environmentObject(taskManager)
        .environmentObject(themeManager)
        .onAppear {
            // Update taskManager with the actual context
            taskManager.updateContext(context)
        }
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
