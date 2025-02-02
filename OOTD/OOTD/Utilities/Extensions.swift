import Foundation

extension String {
    func sanitizedAsURL() -> String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lower = trimmed.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            return trimmed
        } else {
            return "https://\(trimmed)"
        }
    }
}

extension Date {
    /// Returns today's 4 AM in EST
    static func today4AMInEST() -> Date {
        // 1) Create a date in EST
        var calendar = Calendar.current
        if let estTimeZone = TimeZone(identifier: "America/New_York") {
            calendar.timeZone = estTimeZone
        }
        let now = Date()
        // 2) Start of day in local EST
        let startOfDay = calendar.startOfDay(for: now)
        // 3) Add 4 hours
        return calendar.date(byAdding: .hour, value: 4, to: startOfDay) ?? now
    }

    /// Returns 4 AM in EST for "daysAgo" days before today
    static func daysAgo4AMInEST(_ days: Int) -> Date {
        let today4AM = today4AMInEST()
        return Calendar.current.date(byAdding: .day, value: -days, to: today4AM) ?? today4AM
    }

    /// Check if this date is "today" in 4 AM EST terms
    func isSameESTDayAs(_ other: Date) -> Bool {
        var calendar = Calendar.current
        if let estTimeZone = TimeZone(identifier: "America/New_York") {
            calendar.timeZone = estTimeZone
        }
        let comp1 = calendar.dateComponents([.year, .month, .day], from: self)
        let comp2 = calendar.dateComponents([.year, .month, .day], from: other)
        return comp1.year == comp2.year && comp1.month == comp2.month && comp1.day == comp2.day
    }
}
