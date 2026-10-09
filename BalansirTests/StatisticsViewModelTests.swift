import Testing
import Foundation
@testable import Balansir

@Suite("StatisticsViewModel")
@MainActor
struct StatisticsViewModelTests {

    @Test func суммарный_доход_за_период() async {
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .income, amount: 1000, daysAgo: 5),
            .makeTest(type: .income, amount: 500, daysAgo: 10),
            .makeTest(type: .expense, amount: 200, daysAgo: 5)
        ]

        let vm = StatisticsViewModel(entryRepo: entryRepo)
        await vm.load()
        vm.selectedPeriod = .month

        #expect(vm.totalIncome == 1500)
    }

    @Test func суммарный_расход_за_период() async {
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .expense, amount: 300, daysAgo: 5),
            .makeTest(type: .expense, amount: 700, daysAgo: 15),
            .makeTest(type: .income, amount: 1000, daysAgo: 5)
        ]

        let vm = StatisticsViewModel(entryRepo: entryRepo)
        await vm.load()
        vm.selectedPeriod = .month

        #expect(vm.totalExpense == 1000)
    }

    @Test func фильтр_периода_исключает_старые_записи() async {
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .expense, amount: 100, daysAgo: 10),   // в периоде
            .makeTest(type: .expense, amount: 200, daysAgo: 40)    // вне периода
        ]

        let vm = StatisticsViewModel(entryRepo: entryRepo)
        await vm.load()
        vm.selectedPeriod = .month

        #expect(vm.totalExpense == 100)
    }

    @Test func расходы_по_категориям_группируются_и_сортируются_по_убыванию() async {
        let cat1 = CategoryModel.makeTest(name: "Еда")
        let cat2 = CategoryModel.makeTest(name: "Транспорт")
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .expense, amount: 100, daysAgo: 5, category: cat1),
            .makeTest(type: .expense, amount: 200, daysAgo: 5, category: cat1),
            .makeTest(type: .expense, amount: 500, daysAgo: 5, category: cat2)
        ]

        let vm = StatisticsViewModel(entryRepo: entryRepo)
        await vm.load()
        vm.selectedPeriod = .month

        let result = vm.categoryExpenses
        #expect(result.count == 2)
        #expect(result[0].total == 500)  // cat2 первый (больше)
        #expect(result[1].total == 300)  // cat1 второй (100+200)
    }

    @Test func доходные_операции_не_попадают_в_расходы_по_категориям() async {
        let cat = CategoryModel.makeTest(name: "Зарплата", type: .income)
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .income, amount: 5000, daysAgo: 5, category: cat)
        ]

        let vm = StatisticsViewModel(entryRepo: entryRepo)
        await vm.load()
        vm.selectedPeriod = .month

        #expect(vm.categoryExpenses.isEmpty)
    }

    @Test func ошибка_репозитория_устанавливает_errorMessage() async {
        let entryRepo = MockEntryRepository()
        entryRepo.shouldThrow = true

        let vm = StatisticsViewModel(entryRepo: entryRepo)
        await vm.load()

        #expect(vm.errorMessage != nil)
    }
}
