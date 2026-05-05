import XCTest
@testable import AIDD_SAA_2025

final class CountdownVMTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_750_000_000) // fixed reference

    // MARK: - Boundary cases (per spec US1 AS4 + Q1)

    func test_eventInPast_clampsToZero_andHasEnded() {
        let target = now.addingTimeInterval(-3_600) // 1 h ago
        let vm = CountdownVM.from(target: target, now: now)
        XCTAssertEqual(vm.days, 0)
        XCTAssertEqual(vm.hours, 0)
        XCTAssertEqual(vm.minutes, 0)
        XCTAssertTrue(vm.hasEnded)
    }

    func test_eventExactlyNow_isEnded() {
        let vm = CountdownVM.from(target: now, now: now)
        XCTAssertEqual(vm.days, 0)
        XCTAssertEqual(vm.hours, 0)
        XCTAssertEqual(vm.minutes, 0)
        XCTAssertTrue(vm.hasEnded)
    }

    func test_eventOneSecondInFuture_isMinutesZero_butHasEnded() {
        // Sub-minute residue rounds down to 0 minutes; with all three
        // components zero, hasEnded reads true. UI treats this as the
        // event-passed state.
        let target = now.addingTimeInterval(1)
        let vm = CountdownVM.from(target: target, now: now)
        XCTAssertEqual(vm.minutes, 0)
        XCTAssertTrue(vm.hasEnded)
    }

    func test_eventOneMinuteInFuture_isOneMinute() {
        let target = now.addingTimeInterval(60)
        let vm = CountdownVM.from(target: target, now: now)
        XCTAssertEqual(vm.days, 0)
        XCTAssertEqual(vm.hours, 0)
        XCTAssertEqual(vm.minutes, 1)
        XCTAssertFalse(vm.hasEnded)
    }

    // MARK: - Multi-unit math

    func test_eventOneHourInFuture_isOneHourZeroMinutes() {
        let target = now.addingTimeInterval(3_600)
        let vm = CountdownVM.from(target: target, now: now)
        XCTAssertEqual(vm.days, 0)
        XCTAssertEqual(vm.hours, 1)
        XCTAssertEqual(vm.minutes, 0)
        XCTAssertFalse(vm.hasEnded)
    }

    func test_eventOneDayInFuture_isOneDay() {
        let target = now.addingTimeInterval(86_400)
        let vm = CountdownVM.from(target: target, now: now)
        XCTAssertEqual(vm.days, 1)
        XCTAssertEqual(vm.hours, 0)
        XCTAssertEqual(vm.minutes, 0)
    }

    func test_compositeInterval_3d_4h_15m() {
        let days: TimeInterval = 3 * 86_400
        let hours: TimeInterval = 4 * 3_600
        let minutes: TimeInterval = 15 * 60
        let target = now.addingTimeInterval(days + hours + minutes)
        let vm = CountdownVM.from(target: target, now: now)
        XCTAssertEqual(vm.days, 3)
        XCTAssertEqual(vm.hours, 4)
        XCTAssertEqual(vm.minutes, 15)
    }

    func test_subMinuteResidueRoundsDown() {
        // 5 days + 59 seconds — the 59 s gets dropped in floor math.
        let fiveDays: TimeInterval = 5 * 86_400
        let target = now.addingTimeInterval(fiveDays + 59)
        let vm = CountdownVM.from(target: target, now: now)
        XCTAssertEqual(vm.days, 5)
        XCTAssertEqual(vm.hours, 0)
        XCTAssertEqual(vm.minutes, 0)
    }

    // MARK: - Equatable

    func test_equatable_distinctValues() {
        let a = CountdownVM(days: 1, hours: 2, minutes: 3)
        let b = CountdownVM(days: 1, hours: 2, minutes: 3)
        let c = CountdownVM(days: 1, hours: 2, minutes: 4)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
