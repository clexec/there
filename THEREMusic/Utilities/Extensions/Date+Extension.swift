import Foundation

// MARK: - Date Extensions
extension Date {

    var timeAgo: String {
        let diff = Calendar.current.dateComponents(
            [.second, .minute, .hour, .day, .weekOfYear, .month, .year],
            from: self, to: Date()
        )
        if let y = diff.year, y > 0  { return String(format: NSLocalizedString("time_years_ago", comment: ""), y) }
        if let m = diff.month, m > 0 { return String(format: NSLocalizedString("time_months_ago", comment: ""), m) }
        if let w = diff.weekOfYear, w > 0 { return String(format: NSLocalizedString("time_weeks_ago", comment: ""), w) }
        if let d = diff.day, d > 0   { return String(format: NSLocalizedString("time_days_ago", comment: ""), d) }
        if let h = diff.hour, h > 0  { return String(format: NSLocalizedString("time_hours_ago", comment: ""), h) }
        if let min = diff.minute, min > 0 { return String(format: NSLocalizedString("time_minutes_ago", comment: ""), min) }
        return NSLocalizedString("time_just_now", comment: "")
    }

    var formatted_date: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    var iso8601: String {
        ISO8601DateFormatter().string(from: self)
    }

    var isToday: Bool     { Calendar.current.isDateInToday(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }
    var isThisWeek: Bool  { Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear) }
    var isThisMonth: Bool { Calendar.current.isDate(self, equalTo: Date(), toGranularity: .month) }

    static func fromISO8601(_ string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }

    func adding(_ component: Calendar.Component, value: Int) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: self) ?? self
    }

    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var startOfWeek: Date {
        Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
            .let { Calendar.current.date(from: $0) } ?? self
    }
    var startOfMonth: Date {
        Calendar.current.dateComponents([.year, .month], from: self)
            .let { Calendar.current.date(from: $0) } ?? self
    }
}

// MARK: - Int Extensions
extension Int {
    var formattedCount: String {
        switch self {
        case 0..<1_000:       return "\(self)"
        case 1_000..<1_000_000: return String(format: "%.1fK", Double(self) / 1_000)
        default:              return String(format: "%.1fM", Double(self) / 1_000_000)
        }
    }
}

// MARK: - Double Extensions
extension Double {
    var formattedDuration: String {
        let total = Int(self)
        let hours   = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - DateComponents helper
extension DateComponents {
    func `let`<T>(_ block: (DateComponents) -> T) -> T { block(self) }
}
