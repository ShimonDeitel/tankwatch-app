import XCTest
@testable import Tankwatch

final class RateLimiterTests: XCTestCase {

    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.timeZone = TimeZone(identifier: "UTC")
        return utcCalendar.date(from: components)!
    }

    // MARK: - remainingLogsThisMonth

    func test_emptyLogs_remainingIsFullLimit() {
        let now = date(2026, 7, 15)
        let remaining = RateLimiter.remainingLogsThisMonth(existingLogs: [], now: now, calendar: utcCalendar)
        XCTAssertEqual(remaining, 5)
    }

    func test_fourLogsThisMonth_oneRemaining() {
        let now = date(2026, 7, 15)
        let logs = [date(2026, 7, 1), date(2026, 7, 2), date(2026, 7, 3), date(2026, 7, 10)]
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: utcCalendar), 1)
    }

    func test_fiveLogsThisMonth_zeroRemaining() {
        let now = date(2026, 7, 15)
        let logs = (1...5).map { date(2026, 7, $0) }
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: utcCalendar), 0)
    }

    func test_moreThanFiveLogsThisMonth_clampsToZero_notNegative() {
        let now = date(2026, 7, 15)
        let logs = (1...8).map { date(2026, 7, $0) }
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: utcCalendar), 0)
    }

    func test_previousMonthLogsExcluded() {
        let now = date(2026, 7, 1)
        let logs = [date(2026, 6, 28), date(2026, 6, 29), date(2026, 6, 30)]
        // All logs are in June; July has none yet.
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: utcCalendar), 5)
    }

    func test_mixOfPreviousAndCurrentMonth_onlyCurrentCounted() {
        let now = date(2026, 7, 15)
        let logs = [date(2026, 6, 30), date(2026, 6, 29), date(2026, 7, 1), date(2026, 7, 2)]
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: utcCalendar), 3)
    }

    func test_logsOnFirstOfMonth_countTowardThatMonth() {
        let now = date(2026, 7, 1, 0)
        let logs = [date(2026, 7, 1, 1), date(2026, 7, 1, 23)]
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: utcCalendar), 3)
    }

    func test_nowOnFirstOfMonth_previousMonthLastDayExcluded() {
        // A log on June 30 should not count toward a "now" of July 1.
        let now = date(2026, 7, 1)
        let logs = [date(2026, 6, 30, 23)]
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: utcCalendar), 5)
    }

    func test_differentYearSameMonth_notCounted() {
        // July of a previous year must not count toward July this year.
        let now = date(2026, 7, 15)
        let logs = [date(2025, 7, 1), date(2025, 7, 2), date(2025, 7, 3)]
        XCTAssertEqual(RateLimiter.remainingLogsThisMonth(existingLogs: logs, now: now, calendar: utcCalendar), 5)
    }

    // MARK: - canLogReading boundary (5th allowed, 6th blocked)

    func test_fifthLog_isAllowed() {
        let now = date(2026, 7, 15)
        let logs = (1...4).map { date(2026, 7, $0) } // 4 existing logs -> attempting the 5th
        XCTAssertTrue(RateLimiter.canLogReading(isPro: false, existingLogs: logs, now: now, calendar: utcCalendar))
    }

    func test_sixthLog_isBlocked() {
        let now = date(2026, 7, 15)
        let logs = (1...5).map { date(2026, 7, $0) } // 5 existing logs -> attempting the 6th
        XCTAssertFalse(RateLimiter.canLogReading(isPro: false, existingLogs: logs, now: now, calendar: utcCalendar))
    }

    func test_customFreeLimit_respected() {
        let now = date(2026, 7, 15)
        let logs = (1...2).map { date(2026, 7, $0) }
        XCTAssertFalse(RateLimiter.canLogReading(isPro: false, existingLogs: logs, now: now, freeLimit: 2, calendar: utcCalendar))
    }

    // MARK: - Pro bypass

    func test_proUser_alwaysAllowedEvenWithManyLogs() {
        let now = date(2026, 7, 15)
        let logs = (1...20).map { date(2026, 7, $0 % 28 + 1) }
        XCTAssertTrue(RateLimiter.canLogReading(isPro: true, existingLogs: logs, now: now, calendar: utcCalendar))
    }

    func test_proUser_emptyLogs_stillAllowed() {
        let now = date(2026, 7, 15)
        XCTAssertTrue(RateLimiter.canLogReading(isPro: true, existingLogs: [], now: now, calendar: utcCalendar))
    }

    // MARK: - isPro-less overload (isPro OR remaining > 0 contract, caller pre-filters)

    func test_noIsProOverload_matchesRemainingLogic() {
        let now = date(2026, 7, 15)
        let logs = (1...5).map { date(2026, 7, $0) }
        XCTAssertFalse(RateLimiter.canLogReading(existingLogs: logs, now: now, calendar: utcCalendar))
    }
}
