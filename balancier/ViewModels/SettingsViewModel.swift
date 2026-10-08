import Foundation

@Observable
final class SettingsViewModel {
    private(set) var accounts: [AccountModel] = []
    private(set) var categories: [CategoryModel] = []
    private(set) var balances: [UUID: Decimal] = [:]
    var selectedCategoryType = CategoryType.expense
    var errorMessage: String?

    private let accountRepo: any AccountRepository
    private let categoryRepo: any CategoryRepository
    private let entryRepo: any EntryRepository

    init(accountRepo: any AccountRepository, categoryRepo: any CategoryRepository, entryRepo: any EntryRepository) {
        self.accountRepo = accountRepo
        self.categoryRepo = categoryRepo
        self.entryRepo = entryRepo
    }

    var filteredCategories: [CategoryModel] {
        categories.filter { $0.categoryType == selectedCategoryType }
    }

    func load() async {
        do {
            async let a = accountRepo.fetchAll()
            async let c = categoryRepo.fetchAll()
            async let e = entryRepo.fetchAll()
            let (accs, cats, entries) = try await (a, c, e)
            accounts = accs
            categories = cats
            balances = BalanceService.computeBalances(accounts: accs, entries: entries)
        } catch { errorMessage = error.localizedDescription }
    }

    func archive(_ account: AccountModel) async {
        do {
            try await accountRepo.archive(account.id)
            accounts.removeAll { $0.id == account.id }
        } catch { errorMessage = error.localizedDescription }
    }

    func archive(_ category: CategoryModel) async {
        do {
            try await categoryRepo.archive(category.id)
            categories.removeAll { $0.id == category.id }
        } catch { errorMessage = error.localizedDescription }
    }

    func makeAccountFormViewModel(for account: AccountModel?) -> AccountFormViewModel {
        AccountFormViewModel(account: account, accountRepo: accountRepo)
    }

    func makeCategoryFormViewModel(for category: CategoryModel?) -> CategoryFormViewModel {
        CategoryFormViewModel(category: category, categoryRepo: categoryRepo)
    }
}
