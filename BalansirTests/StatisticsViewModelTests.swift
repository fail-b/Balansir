import Testing
import Foundation
@testable import Balansir

@Suite("StatisticsViewModel")
@MainActor
struct StatisticsViewModelTests {

    private func makeVM(_ entries: [EntryModel]) async -> StatisticsViewModel {
        let repo = MockEntryRepository()
        repo.entries = entries
        let today = StatsFixture.today
        let vm = StatisticsViewModel(entryRepo: repo, calendar: StatsFixture.calendar, now: { today }, locale: TestLocale.ru)
        await vm.load()
        return vm
    }

    @Test func заголовок_с_названием_месяца() async {
        let vm = await makeVM([])
        #expect(vm.monthTitle == String(localized: "Expenses in \("октябрь")"))
    }

    @Test func сумма_и_среднее_за_месяц() async {
        let vm = await makeVM([
            StatsFixture.entry(.expense, 800, on: StatsFixture.date(10, 2)),
            StatsFixture.entry(.expense, 800, on: StatsFixture.date(10, 8)),
            StatsFixture.entry(.income, 5000, on: StatsFixture.date(10, 2)),
            StatsFixture.entry(.expense, 9999, on: StatsFixture.date(9, 20)),
        ])
        #expect(vm.monthExpense == 1600)
        #expect(vm.dailyAverage == 200)
    }

    @Test func столбики_прошедшие_сегодня_будущие() async {
        let vm = await makeVM([
            StatsFixture.entry(.expense, 400, on: StatsFixture.date(10, 3)),
            StatsFixture.entry(.expense, 100, on: StatsFixture.date(10, 8)),
        ])
        let bars = vm.dayBars
        #expect(bars.count == 31)
        #expect(bars[0].kind == .past)
        #expect(bars[7].kind == .today)
        #expect(bars[8].kind == .future)
        // Высота — относительно самого большого дня.
        #expect(bars[2].fraction == 1)
        #expect(bars[7].fraction == 0.25)
        #expect(bars[0].fraction == 0)
        #expect(bars[20].fraction == 0)
    }

    @Test func подписи_оси_1_8_15_22_и_последний_день() async {
        let vm = await makeVM([])
        let labels = vm.dayBars.compactMap(\.axisLabel)
        #expect(labels == ["1", "8", "15", "22", "31"])
    }

    @Test func пустой_месяц_даёт_ноль_и_нет_категорий() async {
        let vm = await makeVM([])
        #expect(vm.monthExpense == 0)
        #expect(vm.dailyAverage == 0)
        #expect(vm.dayBars.count == 31)
        #expect(vm.dayBars.allSatisfy { $0.fraction == 0 })
        #expect(vm.categoryStats.isEmpty)
    }

    @Test func категории_проценты_и_прогресс_от_самой_большой() async {
        let food = CategoryModel.makeTest(name: "Еда")
        let transport = CategoryModel.makeTest(name: "Транспорт")
        let vm = await makeVM([
            StatsFixture.entry(.expense, 600, on: StatsFixture.date(10, 2), category: food),
            StatsFixture.entry(.expense, 300, on: StatsFixture.date(10, 3), category: transport),
            StatsFixture.entry(.expense, 100, on: StatsFixture.date(10, 4)),
        ])
        let stats = vm.categoryStats
        #expect(stats.map(\.name) == ["Еда", "Транспорт", String(localized: "No category")])
        #expect(stats.map(\.percent) == [60, 30, 10])
        #expect(stats[0].fraction == 1)
        #expect(stats[1].fraction == 0.5)
        #expect(abs(stats[2].fraction - 1.0 / 6.0) < 1e-9)
        #expect(stats[2].colorHex == nil)
    }

    @Test func ошибка_загрузки_попадает_в_errorMessage() async {
        let repo = MockEntryRepository()
        repo.shouldThrow = true
        let today = StatsFixture.today
        let vm = StatisticsViewModel(entryRepo: repo, calendar: StatsFixture.calendar, now: { today }, locale: TestLocale.ru)
        await vm.load()
        #expect(vm.errorMessage != nil)
    }
}
