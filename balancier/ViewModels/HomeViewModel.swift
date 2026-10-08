import Foundation

@Observable
final class HomeViewModel {
    private(set) var accounts: [AccountModel] = []
    private(set) var recentEntries: [EntryModel] = []
    private(set) var balances: [UUID: Decimal] = [:]
    var errorMessage: String?

    private let accountRepo: any AccountRepository
    private let categoryRepo: any CategoryRepository
    private let entryRepo: any EntryRepository

    init(accountRepo: any AccountRepository, categoryRepo: any CategoryRepository, entryRepo: any EntryRepository) {
        self.accountRepo = accountRepo
        self.categoryRepo = categoryRepo
        self.entryRepo = entryRepo
    }

    var totalBalance: Decimal {
        accounts.reduce(Decimal(0)) { $0 + (balances[$1.id] ?? 0) }
    }

    func load() async {
        do {
            async let a = accountRepo.fetchAll()
            async let e = entryRepo.fetchAll()
            let (accs, entries) = try await (a, e)
            accounts = accs
            recentEntries = Array(entries.prefix(20))
            balances = BalanceService.computeBalances(accounts: accs, entries: entries)
        } catch { errorMessage = error.localizedDescription }
    }

    func makeAddEntryViewModel() -> AddEntryViewModel {
        AddEntryViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo)
    }

    func makeAccountFormViewModel(for account: AccountModel? = nil) -> AccountFormViewModel {
        AccountFormViewModel(account: account, accountRepo: accountRepo)
    }
}
