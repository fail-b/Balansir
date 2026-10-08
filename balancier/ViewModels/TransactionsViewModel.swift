import Foundation

@Observable
final class TransactionsViewModel {
    private(set) var entries: [EntryModel] = []
    var searchText = ""
    var errorMessage: String?

    private let accountRepo: any AccountRepository
    private let categoryRepo: any CategoryRepository
    private let entryRepo: any EntryRepository

    init(accountRepo: any AccountRepository, categoryRepo: any CategoryRepository, entryRepo: any EntryRepository) {
        self.accountRepo = accountRepo
        self.categoryRepo = categoryRepo
        self.entryRepo = entryRepo
    }

    var filteredEntries: [EntryModel] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.displayTitle.localizedCaseInsensitiveContains(searchText) ||
            $0.displayAccount.localizedCaseInsensitiveContains(searchText) ||
            ($0.note?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var groupedEntries: [(date: Date, entries: [EntryModel])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: filteredEntries) { cal.startOfDay(for: $0.date) }
        return groups.sorted { $0.key > $1.key }
            .map { (date: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
    }

    func dayTotal(entries: [EntryModel]) -> Decimal {
        entries.reduce(Decimal(0)) { acc, e in
            switch e.type {
            case .expense: return acc - e.amount
            case .income: return acc + e.amount
            case .transfer: return acc
            }
        }
    }

    func load() async {
        do { entries = try await entryRepo.fetchAll() } catch { errorMessage = error.localizedDescription }
    }

    func delete(_ entry: EntryModel) async {
        do {
            try await entryRepo.delete(entry.id)
            entries.removeAll { $0.id == entry.id }
        } catch { errorMessage = error.localizedDescription }
    }

    func makeAddEntryViewModel() -> AddEntryViewModel {
        AddEntryViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo)
    }

    func makeEditEntryViewModel(for entry: EntryModel) -> AddEntryViewModel {
        AddEntryViewModel(entry: entry, accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo)
    }
}
