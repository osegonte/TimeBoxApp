//
//  TimeParser.swift
//  TimeBoxApp
//
//  Natural language time parsing for task scheduling
//

import Foundation

struct ParsedTime {
    let scheduledDate: Date
    let cleanedTitle: String
    let originalTitle: String
}

class TimeParser {
    static let shared = TimeParser()
    private let calendar = Calendar.current
    
    func parseTimeFromText(_ text: String) -> ParsedTime? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        // Try parsing different time patterns
        if let result = parseTimePattern(trimmed) {
            return result
        }
        
        if let result = parseRelativeTime(trimmed) {
            return result
        }
        
        return nil
    }
    
    // Parse patterns like "3pm task", "10:00 AM meeting", "2:30pm something"
    private func parseTimePattern(_ text: String) -> ParsedTime? {
        // Pattern: number + optional colon + optional minutes + am/pm
        let pattern = #"^(\d{1,2})(?::(\d{2}))?\s*(am|pm|AM|PM)\s+(.+)$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }
        
        // Extract hour
        guard let hourRange = Range(match.range(at: 1), in: text),
              let hour = Int(text[hourRange]) else {
            return nil
        }
        
        // Extract minutes (optional)
        var minute = 0
        if let minuteRange = Range(match.range(at: 2), in: text) {
            minute = Int(text[minuteRange]) ?? 0
        }
        
        // Extract AM/PM
        guard let ampmRange = Range(match.range(at: 3), in: text) else {
            return nil
        }
        let ampm = String(text[ampmRange]).lowercased()
        
        // Extract cleaned title
        guard let titleRange = Range(match.range(at: 4), in: text) else {
            return nil
        }
        let cleanedTitle = String(text[titleRange])
        
        // Convert to 24-hour format
        var hour24 = hour
        if ampm == "pm" && hour != 12 {
            hour24 = hour + 12
        } else if ampm == "am" && hour == 12 {
            hour24 = 0
        }
        
        // Create date
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour24
        components.minute = minute
        
        guard let scheduledDate = calendar.date(from: components) else {
            return nil
        }
        
        // If time is in the past, schedule for tomorrow
        let finalDate: Date
        if scheduledDate < Date() {
            finalDate = calendar.date(byAdding: .day, value: 1, to: scheduledDate) ?? scheduledDate
        } else {
            finalDate = scheduledDate
        }
        
        return ParsedTime(
            scheduledDate: finalDate,
            cleanedTitle: cleanedTitle,
            originalTitle: text
        )
    }
    
    // Parse patterns like "tomorrow 3pm task", "next week meeting"
    private func parseRelativeTime(_ text: String) -> ParsedTime? {
        let lowercased = text.lowercased()
        
        // Check for "tomorrow"
        if lowercased.hasPrefix("tomorrow") {
            let remaining = String(text.dropFirst("tomorrow".count)).trimmingCharacters(in: .whitespaces)
            
            // Try to parse time from remaining text
            if let timeResult = parseTimePattern(remaining) {
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: timeResult.scheduledDate) ?? timeResult.scheduledDate
                return ParsedTime(
                    scheduledDate: tomorrow,
                    cleanedTitle: timeResult.cleanedTitle,
                    originalTitle: text
                )
            }
            
            // No time specified, default to 9am tomorrow
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 9
            components.minute = 0
            
            if let scheduledDate = calendar.date(from: components) {
                return ParsedTime(
                    scheduledDate: scheduledDate,
                    cleanedTitle: remaining,
                    originalTitle: text
                )
            }
        }
        
        return nil
    }
}
