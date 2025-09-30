//
//  CalendarView.swift
//  TimeBoxApp
//
//  FIXED: Proper navigation to daily view
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingDailyView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar grid
                CalendarGridView(
                    currentMonth: $currentMonth,
                    selectedDate: $selectedDate,
                    onDateTap: { date in
                        selectedDate = date
                        showingDailyView = true
                    }
                )
                
                Spacer()
            }
            .background(themeManager.backgroundColor)
            .navigationTitle("Calendar")
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingDailyView) {
                DailyTimelineView(selectedDate: selectedDate)
            }
        }
    }
}

struct CalendarGridView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let onDateTap: (Date) -> Void
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let calendar = Calendar.current
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    private let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header layout
            VStack(spacing: 12) {
                HStack {
                    Text(yearFormatter.string(from: currentMonth))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text(monthFormatter.string(from: currentMonth))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: { changeMonth(-1) }) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                        
                        Button(action: { changeMonth(1) }) {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                    }
                }
                .padding(.horizontal)
                
                Rectangle()
                    .fill(themeManager.primaryTextColor.opacity(0.3))
                    .frame(height: 2)
                    .padding(.horizontal)
            }
            .padding(.top)
            
            // Weekday headers
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Rectangle()
                    .fill(themeManager.secondaryTextColor.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal)
            }
            
            // Calendar days with better spacing
            VStack(spacing: 4) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, date in
                        CalendarDayView(
                            date: date,
                            selectedDate: $selectedDate,
                            currentMonth: currentMonth,
                            taskCount: taskManager.getTasksForDate(date).count,
                            onTap: { onDateTap(date) }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
    
    private var calendarDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end)
        else { return [] }
        
        var days: [Date] = []
        var current = monthFirstWeek.start
        
        while current < monthLastWeek.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        
        return days
    }
    
    private func changeMonth(_ value: Int) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) ?? currentMonth
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    @Binding var selectedDate: Date
    let currentMonth: Date
    let taskCount: Int
    let onTap: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(calendar.isDate(date, inSameDayAs: selectedDate) ? .bold : .medium)
                    .foregroundColor(textColor)
                
                HStack(spacing: 2) {
                    ForEach(0..<min(taskCount, 3), id: \.self) { _ in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                    }
                    
                    if taskCount > 3 {
                        Text("+")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                    }
                }
                .frame(height: 6)
            }
            .frame(width: 40, height: 55)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.blue.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if calendar.isDate(date, inSameDayAs: Date()) {
            return .blue
        } else if calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) {
            return themeManager.primaryTextColor
        } else {
            return themeManager.secondaryTextColor.opacity(0.5)
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(TaskManager(context: ModelContext(ModelContainer.preview)))
        .environmentObject(ThemeManager())
        .modelContainer(ModelContainer.preview)
}
