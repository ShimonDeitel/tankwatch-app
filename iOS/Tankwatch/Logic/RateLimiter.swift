import Foundation

/// Pure, testable free-tier log rate limiting.
/// Free users get `freeLimit` (5) level-check LOGS per rolling calendar month,
/// where "this month" is determined by comparing each log's timestamp's
/// calendar month+year against `now`'s calendar month+year (using the Gregorian
/// calendar in the current time zone at call time — pass a fixed Calendar in
/// tests for determinism).
enum RateLimiter {

    /// Number of existing logs that fall in the same calendar month+year as `now`.
    static func logsThisMonth(existingLogs: [Date], now: Date, calendar: Calendar = .current) -> Int {
        let nowComponents = calendar.dateComponents([.year, .month], from: now)
        return existingLogs.filter { date in
            let components = calendar.dateComponents([.year, .month], from: date)
            return components.year == nowComponents.year && components.month == nowComponents.month
        }.count
    }

    /// How many free logs remain this calendar month, clamped to >= 0.
    static func remainingLogsThisMonth(
        existingLogs: [Date],
        now: Date,
        freeLimit: Int = 5,
        calendar: Calendar = .current
    ) -> Int {
        let used = logsThisMonth(existingLogs: existingLogs, now: now, calendar: calendar)
        return max(0, freeLimit - used)
    }

    /// Whether a new reading may be logged right now: Pro bypasses the limit entirely,
    /// otherwise there must be at least 1 remaining log this month.
    static func canLogReading(
        isPro: Bool,
        existingLogs: [Date],
        now: Date,
        freeLimit: Int = 5,
        calendar: Calendar = .current
    ) -> Bool {
        if isPro { return true }
        return remainingLogsThisMonth(existingLogs: existingLogs, now: now, freeLimit: freeLimit, calendar: calendar) > 0
    }

    /// Convenience overload matching the exact signature requested in the spec
    /// (no explicit isPro parameter — caller is expected to short-circuit with
    /// `isPro ||` before calling, or use the `canLogReading(isPro:...)` overload above).
    static func canLogReading(
        existingLogs: [Date],
        now: Date,
        freeLimit: Int = 5,
        calendar: Calendar = .current
    ) -> Bool {
        remainingLogsThisMonth(existingLogs: existingLogs, now: now, freeLimit: freeLimit, calendar: calendar) > 0
    }
}
