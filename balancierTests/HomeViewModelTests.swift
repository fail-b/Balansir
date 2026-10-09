import Testing
import Foundation
@testable import balancier

@Suite("HomeViewModel")
@MainActor
struct HomeViewModelTests {

    @Test func баланс_начальный_плюс_доходы_минус_расходы() async {
        let account = AccountModel.makeTest(initialBalance: 1000)
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .income, amount: 500, to: account),
            .makeTest(type: .expense, amount: 200, from: account)
        ]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()

        // 1000 + 500 - 200 = 1300
        #expect(vm.totalBalance == 1300)
    }

    @Test func суммарный_баланс_нескольких_счетов() async {
        let a1 = AccountModel.makeTest(name: "A1", initialBalance: 1000)
        let a2 = AccountModel.makeTest(name: "A2", initialBalance: 500)
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [a1, a2]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [.makeTest(type: .expense, amount: 300, from: a1)]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()

        // a1: 1000 - 300 = 700, a2: 500 → итого 1200
        #expect(vm.totalBalance == 1200)
    }

    @Test func перевод_не_меняет_суммарный_баланс() async {
        let a1 = AccountModel.makeTest(name: "A1", initialBalance: 1000)
        let a2 = AccountModel.makeTest(name: "A2", initialBalance: 500)
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [a1, a2]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [.makeTest(type: .transfer, amount: 300, from: a1, to: a2)]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()

        // a1: 1000-300=700, a2: 500+300=800 → итого 1500 (без изменений)
        #expect(vm.totalBalance == 1500)
    }

    @Test func ошибка_репозитория_устанавливает_errorMessage() async {
        let accountRepo = MockAccountRepository()
        accountRepo.shouldThrow = true

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: MockEntryRepository())
        await vm.load()

        #expect(vm.errorMessage != nil)
    }

    @Test func todayExpense_считает_только_расходы_сегодня() async {
        let account = AccountModel.makeTest()
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .expense, amount: 300, daysAgo: 0, from: account),
            .makeTest(type: .expense, amount: 100, daysAgo: 1, from: account),
            .makeTest(type: .income,  amount: 500, daysAgo: 0, to: account),
        ]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()

        #expect(vm.todayExpense == 300)
    }

    @Test func monthExpense_считает_расходы_текущего_месяца() async {
        let account = AccountModel.makeTest()
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .expense, amount: 200, daysAgo: 0, from: account),
            .makeTest(type: .expense, amount: 150, daysAgo: 0, from: account),
            .makeTest(type: .income,  amount: 999, daysAgo: 0, to: account),
        ]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()

        #expect(vm.monthExpense == 350)
    }

    @Test func monthIncome_считает_только_доходы_текущего_месяца() async {
        let account = AccountModel.makeTest()
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .income, amount: 1000, daysAgo: 0, to: account),
            .makeTest(type: .income, amount: 500, daysAgo: 0, to: account),
            .makeTest(type: .expense, amount: 200, daysAgo: 0, from: account),
        ]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()

        #expect(vm.monthIncome == 1500)
    }

    @Test func фильтр_nil_возвращает_все_записи() async {
        let a1 = AccountModel.makeTest(name: "A1")
        let a2 = AccountModel.makeTest(name: "A2")
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [a1, a2]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .expense, amount: 100, from: a1),
            .makeTest(type: .income,  amount: 200, to: a2),
        ]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()

        #expect(vm.filteredEntries.count == 2)
    }

    @Test func фильтр_по_счёту_исключает_чужие_записи() async {
        let a1 = AccountModel.makeTest(name: "A1")
        let a2 = AccountModel.makeTest(name: "A2")
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [a1, a2]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .expense, amount: 100, from: a1),
            .makeTest(type: .expense, amount: 200, from: a2),
        ]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()
        vm.selectedAccountId = a1.id

        #expect(vm.filteredEntries.count == 1)
        #expect(vm.filteredEntries[0].amount == 100)
    }

    @Test func фильтр_перевод_попадает_как_источник() async {
        let a1 = AccountModel.makeTest(name: "A1")
        let a2 = AccountModel.makeTest(name: "A2")
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [a1, a2]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [.makeTest(type: .transfer, amount: 500, from: a1, to: a2)]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()
        vm.selectedAccountId = a1.id

        #expect(vm.filteredEntries.count == 1)
    }

    @Test func фильтр_перевод_попадает_как_получатель() async {
        let a1 = AccountModel.makeTest(name: "A1")
        let a2 = AccountModel.makeTest(name: "A2")
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [a1, a2]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [.makeTest(type: .transfer, amount: 500, from: a1, to: a2)]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()
        vm.selectedAccountId = a2.id

        #expect(vm.filteredEntries.count == 1)
    }

    @Test func entriesByDay_группирует_записи_по_дням() async {
        let account = AccountModel.makeTest()
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .expense, amount: 100, daysAgo: 0, from: account),
            .makeTest(type: .expense, amount: 200, daysAgo: 0, from: account),
            .makeTest(type: .expense, amount: 300, daysAgo: 1, from: account),
        ]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()

        #expect(vm.entriesByDay.count == 2)
        // Первая группа — сегодня (daysAgo: 0), 2 записи, расход дня 300
        #expect(vm.entriesByDay[0].entries.count == 2)
        #expect(vm.entriesByDay[0].dayExpense == 300)
    }

    @Test func entriesByDay_dayExpense_не_включает_доходы() async {
        let account = AccountModel.makeTest()
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [
            .makeTest(type: .expense, amount: 400, daysAgo: 0, from: account),
            .makeTest(type: .income,  amount: 999, daysAgo: 0, to: account),
        ]

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()

        #expect(vm.entriesByDay[0].dayExpense == 400)
    }
}
