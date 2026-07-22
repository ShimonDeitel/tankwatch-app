import XCTest
@testable import Tankwatch

/// Test double letting us control authorization outcome and observe what
/// would have been scheduled, without touching real UNUserNotificationCenter.
final class MockNotificationScheduler: NotificationScheduling {
    var authorizationGranted = true
    var authorizationError: Error?
    var scheduleError: Error?

    private(set) var scheduledRequests: [(id: String, title: String, body: String, fireDate: Date)] = []
    private(set) var authorizationRequestCount = 0

    func requestAuthorization() async throws -> Bool {
        authorizationRequestCount += 1
        if let authorizationError { throw authorizationError }
        return authorizationGranted
    }

    func scheduleNotification(id: String, title: String, body: String, fireDate: Date) async throws {
        if let scheduleError { throw scheduleError }
        scheduledRequests.append((id, title, body, fireDate))
    }

    func hasPendingNotification(id: String) async -> Bool {
        scheduledRequests.contains { $0.id == id }
    }
}

struct TestError: Error {}

final class UpgradeNudgeSchedulerTests: XCTestCase {

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

    // MARK: - fireDate computation

    func test_fireDate_isTwentyHoursLater() {
        let now = date(2026, 7, 15, 10)
        let fire = UpgradeNudgeScheduler.fireDate(hittingLimitAt: now, calendar: utcCalendar)
        let expected = utcCalendar.date(byAdding: .hour, value: 20, to: now)!
        XCTAssertEqual(fire, expected)
    }

    func test_fireDate_crossesDayBoundaryCorrectly() {
        let now = date(2026, 7, 15, 20) // 20:00
        let fire = UpgradeNudgeScheduler.fireDate(hittingLimitAt: now, calendar: utcCalendar)
        // 20:00 + 20h = 16:00 the next day.
        let components = utcCalendar.dateComponents([.day, .hour], from: fire)
        XCTAssertEqual(components.day, 16)
        XCTAssertEqual(components.hour, 16)
    }

    // MARK: - monthKey / notificationID

    func test_monthKey_formatsYearMonth() {
        XCTAssertEqual(UpgradeNudgeScheduler.monthKey(for: date(2026, 7, 15), calendar: utcCalendar), "2026-07")
        XCTAssertEqual(UpgradeNudgeScheduler.monthKey(for: date(2026, 12, 1), calendar: utcCalendar), "2026-12")
        XCTAssertEqual(UpgradeNudgeScheduler.monthKey(for: date(2027, 1, 1), calendar: utcCalendar), "2027-01")
    }

    func test_notificationID_includesMonthKey() {
        let id = UpgradeNudgeScheduler.notificationID(for: date(2026, 7, 15), calendar: utcCalendar)
        XCTAssertTrue(id.contains("2026-07"))
    }

    // MARK: - handleLimitHit behavior

    func test_handleLimitHit_grantedPermission_schedulesOneNotification() async {
        let mock = MockNotificationScheduler()
        mock.authorizationGranted = true
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: utcCalendar)

        let now = date(2026, 7, 15)
        let result = await scheduler.handleLimitHit(now: now)

        XCTAssertTrue(result)
        XCTAssertEqual(mock.scheduledRequests.count, 1)
        XCTAssertEqual(mock.authorizationRequestCount, 1)
    }

    func test_handleLimitHit_deniedPermission_schedulesNothing() async {
        let mock = MockNotificationScheduler()
        mock.authorizationGranted = false
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: utcCalendar)

        let result = await scheduler.handleLimitHit(now: date(2026, 7, 15))

        XCTAssertFalse(result)
        XCTAssertEqual(mock.scheduledRequests.count, 0)
    }

    func test_handleLimitHit_authorizationThrows_schedulesNothing() async {
        let mock = MockNotificationScheduler()
        mock.authorizationError = TestError()
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: utcCalendar)

        let result = await scheduler.handleLimitHit(now: date(2026, 7, 15))

        XCTAssertFalse(result)
        XCTAssertEqual(mock.scheduledRequests.count, 0)
    }

    func test_handleLimitHit_calledTwiceSameMonth_onlySchedulesOnce() async {
        let mock = MockNotificationScheduler()
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: utcCalendar)

        let firstHit = date(2026, 7, 15)
        let secondHit = date(2026, 7, 28) // later, same month

        let firstResult = await scheduler.handleLimitHit(now: firstHit)
        let secondResult = await scheduler.handleLimitHit(now: secondHit)

        XCTAssertTrue(firstResult)
        XCTAssertFalse(secondResult)
        XCTAssertEqual(mock.scheduledRequests.count, 1)
        XCTAssertEqual(mock.authorizationRequestCount, 1)
    }

    func test_handleLimitHit_calledInDifferentMonths_schedulesOncePerMonth() async {
        let mock = MockNotificationScheduler()
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: utcCalendar)

        let julyHit = date(2026, 7, 15)
        let augustHit = date(2026, 8, 3)

        let julyResult = await scheduler.handleLimitHit(now: julyHit)
        let augustResult = await scheduler.handleLimitHit(now: augustHit)

        XCTAssertTrue(julyResult)
        XCTAssertTrue(augustResult)
        XCTAssertEqual(mock.scheduledRequests.count, 2)
        XCTAssertNotEqual(mock.scheduledRequests[0].id, mock.scheduledRequests[1].id)
    }

    func test_hasScheduledThisMonth_reflectsPriorMark() {
        let mock = MockNotificationScheduler()
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: utcCalendar)
        let now = date(2026, 7, 15)

        XCTAssertFalse(scheduler.hasScheduledThisMonth(now: now))
        scheduler.markScheduled(for: now)
        XCTAssertTrue(scheduler.hasScheduledThisMonth(now: now))
        // A different month should still read as not-scheduled.
        XCTAssertFalse(scheduler.hasScheduledThisMonth(now: date(2026, 8, 1)))
    }

    func test_preSeededScheduledMonths_preventsDuplicateOnFirstCall() async {
        let mock = MockNotificationScheduler()
        let now = date(2026, 7, 15)
        let alreadyKey = UpgradeNudgeScheduler.monthKey(for: now, calendar: utcCalendar)
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: utcCalendar, alreadyScheduledMonthKeys: [alreadyKey])

        let result = await scheduler.handleLimitHit(now: now)

        XCTAssertFalse(result)
        XCTAssertEqual(mock.scheduledRequests.count, 0)
        XCTAssertEqual(mock.authorizationRequestCount, 0)
    }

    func test_scheduleFailure_doesNotMarkMonthAsScheduled() async {
        let mock = MockNotificationScheduler()
        mock.scheduleError = TestError()
        let scheduler = UpgradeNudgeScheduler(scheduler: mock, calendar: utcCalendar)
        let now = date(2026, 7, 15)

        let result = await scheduler.handleLimitHit(now: now)

        XCTAssertFalse(result)
        XCTAssertFalse(scheduler.hasScheduledThisMonth(now: now))
    }
}
