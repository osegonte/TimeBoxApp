//
//  TimeBoxAppApp.swift
//  TimeBoxApp
//
//  FIXED: Added migration support with correct parameter order
//

import SwiftUI
import SwiftData

@main
struct TimeBoxAppApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .modelContainer(createModelContainer())
        }
    }
    
    // MIGRATION: Enhanced container creation with migration support
    private func createModelContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(
                for: TaskItem.self, SleepScheduleItem.self,
                configurations: ModelConfiguration(
                    "TimeBoxAppData",
                    isStoredInMemoryOnly: false,
                    allowsSave: true
                )
            )
            
            // MIGRATION: Perform migration check on app launch
            let context = container.mainContext
            DataMigrationManager.shared.performMigrationIfNeeded(context: context)
            
            return container
            
        } catch {
            print("Failed to create ModelContainer: \(error)")
            
            // MIGRATION: Fallback container creation
            do {
                let fallbackContainer = try ModelContainer(for: TaskItem.self, SleepScheduleItem.self)
                print("Created fallback container")
                return fallbackContainer
            } catch {
                fatalError("Failed to create even fallback container: \(error)")
            }
        }
    }
}
