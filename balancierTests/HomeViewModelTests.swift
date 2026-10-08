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

    @Test func последние_операции_ограничены_двадцатью() async {
        let account = AccountModel.makeTest()
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = (0..<30).map { _ in .makeTest(type: .expense, amount: 10, from: account) }

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()

        #expect(vm.recentEntries.count == 20)
    }

    @Test func ошибка_репозитория_устанавливает_errorMessage() async {
        let accountRepo = MockAccountRepository()
        accountRepo.shouldThrow = true

        let vm = HomeViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: MockEntryRepository())
        await vm.load()

        #expect(vm.errorMessage != nil)
    }
}
