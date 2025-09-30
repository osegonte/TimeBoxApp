//
//  ContentView.swift
//  TimeBoxApp
//
//  Simplified: Tasks only, no calendar
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var themeManager = ThemeManager()
    
    var body: some View {
        TasksView()
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
