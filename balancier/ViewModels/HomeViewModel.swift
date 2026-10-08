import Foundation

@Observable
final class HomeViewModel {
    private(set) var accounts: [AccountModel] = []
    private(set) var recentEntries: [EntryModel] = []
    private(set) var balances: [UUID: Decimal] = [:]

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
            balances = computeBalances(accounts: accs, entries: entries)
        } catch {}
    }

    func makeAddEntryViewModel() -> AddEntryViewModel {
        AddEntryViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo)
    }

    func makeAccountFormViewModel(for account: AccountModel? = nil) -> AccountFormViewModel {
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
