import Testing
import Foundation
@testable import Balansir

@Suite("AccountsViewModel")
@MainActor
struct AccountsViewModelTests {

    @Test func load_заполняет_счета_и_категории() async {
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [.makeTest(name: "Счёт 1"), .makeTest(name: "Счёт 2")]
        let categoryRepo = MockCategoryRepository()
        categoryRepo.categories = [.makeTest(name: "Еда"), .makeTest(name: "Зарплата", type: .income)]
        let vm = AccountsViewModel(
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
        let vm = AccountsViewModel(
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
        let vm = AccountsViewModel(
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
        let vm = AccountsViewModel(
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
        let vm = AccountsViewModel(
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
        let vm = AccountsViewModel(
            accountRepo: accountRepo,
            categoryRepo: MockCategoryRepository(),
            entryRepo: MockEntryRepository()
        )
        await vm.load()
        #expect(vm.errorMessage != nil)
    }

    // MARK: «Всего на счетах» и скрытие с отменой (§4.5)

    private func makeVM(_ accountRepo: MockAccountRepository, entries: [EntryModel] = []) -> AccountsViewModel {
        let entryRepo = MockEntryRepository()
        entryRepo.entries = entries
        return AccountsViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
    }

    @Test func totalBalance_суммирует_балансы_с_операциями() async {
        let a1 = AccountModel.makeTest(name: "A1", initialBalance: 1000)
        let a2 = AccountModel.makeTest(name: "A2", initialBalance: -200)
        let repo = MockAccountRepository()
        repo.accounts = [a1, a2]
        let vm = makeVM(repo, entries: [.makeTest(type: .expense, amount: 300, from: a1)])
        await vm.load()
        // 700 + (−200) = 500
        #expect(vm.totalBalance == 500)
    }

    @Test func archive_запоминает_счёт_для_отмены() async {
        let account = AccountModel.makeTest()
        let repo = MockAccountRepository()
        repo.accounts = [account]
        let vm = makeVM(repo)
        await vm.load()
        await vm.archive(account)
        #expect(vm.recentlyArchived?.id == account.id)
        await vm.load()
        #expect(vm.accounts.isEmpty)   // и в репозитории скрыт
    }

    @Test func undoArchive_возвращает_счёт() async {
        let account = AccountModel.makeTest()
        let repo = MockAccountRepository()
        repo.accounts = [account]
        let vm = makeVM(repo)
        await vm.load()
        await vm.archive(account)
        await vm.undoArchive()
        #expect(vm.accounts.map(\.id) == [account.id])
        #expect(vm.recentlyArchived == nil)
    }

    @Test func dismissUndo_оставляет_счёт_скрытым() async {
        let account = AccountModel.makeTest()
        let repo = MockAccountRepository()
        repo.accounts = [account]
        let vm = makeVM(repo)
        await vm.load()
        await vm.archive(account)
        vm.dismissUndo()
        await vm.undoArchive()   // плашки уже нет — ничего не делает
        await vm.load()
        #expect(vm.accounts.isEmpty)
        #expect(vm.recentlyArchived == nil)
    }

    @Test func ошибка_отмены_показывает_ошибку() async {
        let account = AccountModel.makeTest()
        let repo = MockAccountRepository()
        repo.accounts = [account]
        let vm = makeVM(repo)
        await vm.load()
        await vm.archive(account)
        repo.shouldThrow = true
        await vm.undoArchive()
        #expect(vm.errorMessage != nil)
    }
}
