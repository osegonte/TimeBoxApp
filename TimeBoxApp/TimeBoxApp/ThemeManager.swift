//
//  ThemeManager.swift
//  TimeBoxApp
//
//  Fixed color theming for proper dark mode
//

import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true // Default to dark mode
    
    // Primary colors that adapt to theme
    var primaryTextColor: Color {
        isDarkMode ? .white : .black
    }
    
    var secondaryTextColor: Color {
        isDarkMode ? Color.white.opacity(0.7) : Color.black.opacity(0.6)
    }
    
    var backgroundColor: Color {
        isDarkMode ? Color.black : Color.white
    }
    
    var cardBackgroundColor: Color {
        isDarkMode ? Color(.systemGray6) : Color(.systemGray6)
    }
    
    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
    }
}
