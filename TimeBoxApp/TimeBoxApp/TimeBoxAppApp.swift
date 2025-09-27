//
//  TimeBoxAppApp.swift
//  TimeBoxApp
//
//  Proper color scheme setup
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
                .modelContainer(for: [TaskItem.self, SleepScheduleItem.self])
        }
    }
}
