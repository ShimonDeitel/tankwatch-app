import Foundation
import UserNotifications

/// Thin protocol wrapping the real UNUserNotificationCenter calls we need, so
/// the scheduling LOGIC (computed fire date, per-month dedup) can be unit
/// tested without touching real notification permissions.
protocol NotificationScheduling {
    func requestAuthorization() async throws -> Bool
    func scheduleNotification(id: String, title: String, body: String, fireDate: Date) async throws
    func hasPendingNotification(id: String) async -> Bool
}

/// Real implementation backed by UNUserNotificationCenter.
final class SystemNotificationScheduler: NotificationScheduling {
    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleNotification(id: String, title: String, body: String, fireDate: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let interval = max(1, fireDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }

    func hasPendingNotification(id: String) async -> Bool {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.contains { $0.identifier == id }
    }
}

/// Schedules exactly ONE local notification the first time a free user hits
/// their monthly log limit, reminding them ~20 hours later about Pro.
/// Dedup is per calendar month: only one such notification should ever be
/// scheduled per month, even if the limit-hit path is triggered repeatedly.
final class UpgradeNudgeScheduler {
    static let notificationIDPrefix = "tankwatch.upgrade-nudge"
    static let reminderDelayHours: Double = 20

    private let scheduler: NotificationScheduling
    private let calendar: Calendar
    private var scheduledMonthKeys: Set<String>

    init(
        scheduler: NotificationScheduling = SystemNotificationScheduler(),
        calendar: Calendar = .current,
        alreadyScheduledMonthKeys: Set<String> = []
    ) {
        self.scheduler = scheduler
        self.calendar = calendar
        self.scheduledMonthKeys = alreadyScheduledMonthKeys
    }

    /// Deterministic identifier for "the month containing `date`", e.g. "2026-07".
    static func monthKey(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        return String(format: "%04d-%02d", year, month)
    }

    /// The notification identifier used for a given month's nudge.
    static func notificationID(for date: Date, calendar: Calendar = .current) -> String {
        "\(notificationIDPrefix).\(monthKey(for: date, calendar: calendar))"
    }

    /// Pure computation of when the reminder should fire, given the moment the
    /// user hit their limit.
    static func fireDate(hittingLimitAt now: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .hour, value: Int(reminderDelayHours), to: now) ?? now.addingTimeInterval(reminderDelayHours * 3600)
    }

    /// Whether a nudge has already been scheduled/recorded for the calendar month containing `now`.
    func hasScheduledThisMonth(now: Date) -> Bool {
        scheduledMonthKeys.contains(Self.monthKey(for: now, calendar: calendar))
    }

    /// Marks the month containing `now` as having a scheduled nudge (used internally and
    /// exposed for test setup/verification).
    func markScheduled(for now: Date) {
        scheduledMonthKeys.insert(Self.monthKey(for: now, calendar: calendar))
    }

    /// Call the first time a free user hits their monthly limit. Requests
    /// notification permission contextually and, if granted and no nudge has
    /// already been scheduled for this month, schedules exactly one reminder
    /// ~20 hours later. Safe to call multiple times per month (deduped).
    @discardableResult
    func handleLimitHit(now: Date = Date()) async -> Bool {
        guard !hasScheduledThisMonth(now: now) else { return false }

        do {
            let granted = try await scheduler.requestAuthorization()
            guard granted else { return false }
        } catch {
            return false
        }

        let id = Self.notificationID(for: now, calendar: calendar)
        let fire = Self.fireDate(hittingLimitAt: now, calendar: calendar)

        do {
            try await scheduler.scheduleNotification(
                id: id,
                title: "Still tracking tank levels this month?",
                body: "Upgrade to Tankwatch Pro for unlimited logging.",
                fireDate: fire
            )
            markScheduled(for: now)
            return true
        } catch {
            return false
        }
    }
}
