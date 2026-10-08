import Foundation

@Observable
final class SettingsViewModel {
    private(set) var accounts: [AccountModel] = []
    private(set) var categories: [CategoryModel] = []
    private(set) var balances: [UUID: Decimal] = [:]
    var selectedCategoryType = CategoryType.expense

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
            balances = computeBalances(accounts: accs, entries: entries)
        } catch {}
    }

    func archive(_ account: AccountModel) async {
        do {
            try await accountRepo.archive(account.id)
            accounts.removeAll { $0.id == account.id }
        } catch {}
    }

    func makeAccountFormViewModel(for account: AccountModel?) -> AccountFormViewModel {
        AccountFormViewModel(account: account, accountRepo: accountRepo)
    }

    private func computeBalances(accounts: [AccountModel], entries: [EntryModel]) -> [UUID: Decimal] {
        var result: [UUID: Decimal] = [:]
        for a in accounts { result[a.id] = a.initialBalance }
        for e in entries {
            if let id = e.fromAccount?.id { result[id, default: 0] -= e.amount }
            if let id = e.toAccount?.id { result[id, default: 0] += e.amount }
        }
        return result
    }
}
