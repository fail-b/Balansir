import Testing
import Foundation
@testable import Balansir

@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {

    @Test func load_заполняет_счета_и_категории() async {
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [.makeTest(name: "Счёт 1"), .makeTest(name: "Счёт 2")]
        let categoryRepo = MockCategoryRepository()
        categoryRepo.categories = [.makeTest(name: "Еда"), .makeTest(name: "Зарплата", type: .income)]
        let vm = SettingsViewModel(
            accountRepo: accountRepo,
            categoryRepo: categoryRepo,
            entryRepo: MockEntryRepository()
        )
        await vm.load()
        #expect(vm.accounts.count == 2)
        #expect(vm.categories.count == 2)
    }

    @Test func load_вычисляет_балансы() async {
        let account = AccountModel.makeTest(initialBalance: 1000)
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let entryRepo = MockEntryRepository()
        entryRepo.entries = [.makeTest(type: .expense, amount: 300, from: account)]
        let vm = SettingsViewModel(
            accountRepo: accountRepo,
            categoryRepo: MockCategoryRepository(),
            entryRepo: entryRepo
        )
        await vm.load()
        #expect(vm.balances[account.id] == 700)
    }

    @Test func filteredCategories_фильтрует_по_типу() async {
        let categoryRepo = MockCategoryRepository()
        categoryRepo.categories = [
            .makeTest(name: "Еда", type: .expense),
            .makeTest(name: "Транспорт", type: .expense),
            .makeTest(name: "Зарплата", type: .income),
        ]
        let vm = SettingsViewModel(
            accountRepo: MockAccountRepository(),
            categoryRepo: categoryRepo,
            entryRepo: MockEntryRepository()
        )
        await vm.load()
        vm.selectedCategoryType = .expense
        #expect(vm.filteredCategories.count == 2)
        vm.selectedCategoryType = .income
        #expect(vm.filteredCategories.count == 1)
    }

    @Test func archive_счёт_удаляет_из_списка() async {
        let account = AccountModel.makeTest()
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let vm = SettingsViewModel(
            accountRepo: accountRepo,
            categoryRepo: MockCategoryRepository(),
            entryRepo: MockEntryRepository()
        )
        await vm.load()
        await vm.archive(account)
        #expect(vm.accounts.isEmpty)
    }

    @Test func archive_категория_удаляет_из_списка() async {
        let category = CategoryModel.makeTest()
        let categoryRepo = MockCategoryRepository()
        categoryRepo.categories = [category]
        let vm = SettingsViewModel(
            accountRepo: MockAccountRepository(),
            categoryRepo: categoryRepo,
            entryRepo: MockEntryRepository()
        )
        await vm.load()
        await vm.archive(category)
        #expect(vm.categories.isEmpty)
    }

    @Test func ошибка_репозитория_устанавливает_errorMessage() async {
        let accountRepo = MockAccountRepository()
        accountRepo.shouldThrow = true
        let vm = SettingsViewModel(
            accountRepo: accountRepo,
            categoryRepo: MockCategoryRepository(),
            entryRepo: MockEntryRepository()
        )
        await vm.load()
        #expect(vm.errorMessage != nil)
    }
}
