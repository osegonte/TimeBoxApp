//
//  CalendarView.swift
//  TimeBoxApp
//
//  Fixed: Month name only, subtle year indicator in corner
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @EnvironmentObject private var taskManager: TaskManager
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedDate = Date()
    @State private var showingDailyView = false
    @State private var displayedMonth = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Navigation header with subtle year
                HStack {
                    // Subtle year indicator in left corner
                    Text(displayedMonth, format: .dateTime.year())
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.leading, 4)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.primaryTextColor)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Month section header - just month name
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(displayedMonth, format: .dateTime.month(.wide))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
                    Rectangle()
                        .fill(themeManager.secondaryTextColor.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
                
                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(calendar.shortWeekdaySymbols, id: \.self) { weekday in
                        Text(weekday.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.secondaryTextColor)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Calendar grid
                let cellSize = (geometry.size.width - 60) / 7
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 12) {
                    ForEach(daysInMonth, id: \.self) { date in
                        CalendarDayCell(
                            date: date,
                            tasks: taskManager.getTasksForDate(date),
                            isToday: calendar.isDateInToday(date),
                            isCurrentMonth: calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month),
                            cellSize: cellSize
                        )
                        .frame(width: cellSize, height: cellSize)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDate = date
                            showingDailyView = true
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer(minLength: 120)
            }
        }
        .background(themeManager.backgroundColor)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingDailyView) {
            DailyTimelineView(selectedDate: selectedDate)
        }
        .onAppear {
            taskManager.objectWillChange.send()
        }
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        
        let monthStart = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let daysFromFirstWeekday = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        guard let calendarStart = calendar.date(byAdding: .day, value: -daysFromFirstWeekday, to: monthStart) else { return [] }
        
        var days: [Date] = []
        var currentDate = calendarStart
        
        let weeksNeeded = calendar.range(of: .weekOfMonth, in: .month, for: displayedMonth)?.count ?? 6
        
        for _ in 0..<(weeksNeeded * 7) {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let tasks: [TaskItem]
    let isToday: Bool
    let isCurrentMonth: Bool
    let cellSize: CGFloat
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: min(cellSize * 0.28, 20), weight: isToday ? .bold : .medium))
                .foregroundColor(textColor)
                .frame(width: min(cellSize * 0.6, 32), height: min(cellSize * 0.6, 32))
                .background(
                    Circle()
                        .fill(isToday ? .blue : Color.clear)
                )
            
            if !tasks.isEmpty {
                HStack(spacing: 3) {
                    ForEach(Array(tasks.prefix(3).enumerated()), id: \.offset) { _, task in
                        Circle()
                            .fill(task.displayColor)
                            .frame(width: 6, height: 6)
                    }
                    
                    if tasks.count > 3 {
                        Text("+")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
                .frame(height: 12)
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 12)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
    }
    
    private var textColor: Color {
        if isToday {
            return .white
        } else if !isCurrentMonth {
            return themeManager.secondaryTextColor.opacity(0.3)
        } else {
            return themeManager.primaryTextColor
        }
    }
    
    private var backgroundColor: Color {
        if !tasks.isEmpty && isCurrentMonth {
            return themeManager.cardBackgroundColor.opacity(0.5)
        } else {
            return Color.clear
        }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date? {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)
    }
}

#Preview {
    CalendarView()
        .environmentObject(TaskManager(context: ModelContext(ModelContainer.preview)))
        .environmentObject(ThemeManager())
        .modelContainer(ModelContainer.preview)
}
