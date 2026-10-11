import Testing
import Foundation
@testable import Balansir

/// Фиксированный календарь и даты октября 2026 — расчёты не зависят от часового пояса машины.
@MainActor
enum StatsFixture {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Moscow")!
        return cal
    }()

    static func date(_ month: Int, _ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    /// «Сегодня» в тестах — 8 октября 2026.
    static let today = date(10, 8)

    static func entry(_ type: EntryType, _ amount: Decimal, on date: Date, category: CategoryModel? = nil) -> EntryModel {
        EntryModel(
            id: UUID(), date: date, type: type, amount: amount, currency: "RUB",
            note: nil, tags: nil, isRecurring: false, isSoftDeleted: false,
            createdAt: date, updatedAt: date,
            fromAccount: nil, toAccount: nil, category: category
        )
    }
}

@Suite("StatisticsService")
@MainActor
struct StatisticsServiceTests {
    private let cal = StatsFixture.calendar
    private var october: DateInterval { StatisticsService.monthInterval(containing: StatsFixture.today, calendar: cal) }

    @Test("Название месяца — с заглавной, в именительном падеже")
    func monthName() {
        #expect(StatisticsService.monthName(for: StatsFixture.today, calendar: cal) == "Октябрь")
        #expect(StatisticsService.monthName(for: StatsFixture.date(5, 3), calendar: cal) == "Май")
    }

    @Test func месяц_от_первого_числа_до_первого_числа_следующего() {
        #expect(october.start == cal.date(from: DateComponents(year: 2026, month: 10, day: 1))!)
        #expect(october.end == cal.date(from: DateComponents(year: 2026, month: 11, day: 1))!)
    }

    @Test func сумма_расходов_только_за_месяц_и_только_расходы() {
        let entries = [
            StatsFixture.entry(.expense, 100, on: StatsFixture.date(10, 1, hour: 0)),
            StatsFixture.entry(.expense, 200, on: StatsFixture.date(10, 31, hour: 23)),
            StatsFixture.entry(.expense, 999, on: StatsFixture.date(9, 30, hour: 23)),   // прошлый месяц
            StatsFixture.entry(.expense, 999, on: StatsFixture.date(11, 1, hour: 0)),    // следующий месяц
            StatsFixture.entry(.income, 5000, on: StatsFixture.date(10, 5)),
            StatsFixture.entry(.transfer, 700, on: StatsFixture.date(10, 5)),
        ]
        #expect(StatisticsService.total(of: .expense, in: entries, interval: october) == 300)
        #expect(StatisticsService.total(of: .income, in: entries, interval: october) == 5000)
    }

    @Test func расходы_по_дням_на_все_дни_месяца() {
        let entries = [
            StatsFixture.entry(.expense, 100, on: StatsFixture.date(10, 1)),
            StatsFixture.entry(.expense, 50, on: StatsFixture.date(10, 1, hour: 20)),
            StatsFixture.entry(.expense, 300, on: StatsFixture.date(10, 8)),
            StatsFixture.entry(.income, 1000, on: StatsFixture.date(10, 8)),
            StatsFixture.entry(.expense, 999, on: StatsFixture.date(9, 30)),
        ]
        let daily = StatisticsService.dailyExpenses(in: entries, month: october, calendar: cal)
        #expect(daily.count == 31)
        #expect(daily[0] == 150)
        #expect(daily[7] == 300)
        #expect(daily.reduce(0, +) == 450)
    }

    @Test func в_феврале_28_дней() {
        let feb = StatisticsService.monthInterval(containing: StatsFixture.date(2, 10), calendar: cal)
        #expect(StatisticsService.dailyExpenses(in: [], month: feb, calendar: cal).count == 28)
    }

    @Test func среднее_в_день_включает_сегодняшний_день() {
        // Макет: 84 320 ₽ за 8 дней → 10 540 ₽ в день.
        let avg = StatisticsService.dailyAverage(total: 84320, today: StatsFixture.today, calendar: cal)
        #expect(avg == 10540)
    }

    @Test func среднее_первого_числа_равно_сумме() {
        let avg = StatisticsService.dailyAverage(total: 500, today: StatsFixture.date(10, 1, hour: 0), calendar: cal)
        #expect(avg == 500)
    }

    @Test func категории_группируются_и_сортируются_по_убыванию() {
        let food = CategoryModel.makeTest(name: "Еда")
        let transport = CategoryModel.makeTest(name: "Транспорт")
        let entries = [
            StatsFixture.entry(.expense, 100, on: StatsFixture.date(10, 2), category: food),
            StatsFixture.entry(.expense, 200, on: StatsFixture.date(10, 3), category: food),
            StatsFixture.entry(.expense, 500, on: StatsFixture.date(10, 3), category: transport),
            StatsFixture.entry(.expense, 40, on: StatsFixture.date(10, 4)),                       // без категории
            StatsFixture.entry(.expense, 900, on: StatsFixture.date(9, 3), category: food),      // прошлый месяц
            StatsFixture.entry(.income, 900, on: StatsFixture.date(10, 3), category: food),
        ]
        let result = StatisticsService.expensesByCategory(in: entries, interval: october)
        #expect(result.map(\.total) == [500, 300, 40])
        #expect(result[0].category?.id == transport.id)
        #expect(result[1].category?.id == food.id)
        #expect(result[2].category == nil)
    }
}
