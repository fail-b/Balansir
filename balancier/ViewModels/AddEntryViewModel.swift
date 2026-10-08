import Foundation

@Observable
final class AddEntryViewModel {
    private(set) var accounts: [AccountModel] = []
    private(set) var categories: [CategoryModel] = []

    var selectedType = EntryType.expense
    var amountString = "0"
    var selectedAccount: AccountModel?
    var selectedToAccount: AccountModel?
    var selectedCategory: CategoryModel?
    var note = ""
    var date = Date()
    var errorMessage: String?

    private let editingEntry: EntryModel?
    private var hasLoaded = false
    private let accountRepo: any AccountRepository
    private let categoryRepo: any CategoryRepository
    private let entryRepo: any EntryRepository

    init(entry: EntryModel? = nil, accountRepo: any AccountRepository, categoryRepo: any CategoryRepository, entryRepo: any EntryRepository) {
        self.editingEntry = entry
        self.accountRepo = accountRepo
        self.categoryRepo = categoryRepo
        self.entryRepo = entryRepo
    }

    var isEditing: Bool { editingEntry != nil }
    var amount: Decimal { Decimal(string: amountString) ?? 0 }

    var filteredCategories: [CategoryModel] {
        categories.filter { $0.categoryType == selectedType.categoryType }
    }

    var canSave: Bool {
        guard amount > 0 else { return false }
        switch selectedType {
        case .expense, .income: return selectedAccount != nil && selectedCategory != nil
        case .transfer: return selectedAccount != nil && selectedToAccount != nil && selectedAccount?.id != selectedToAccount?.id
        }
    }

    func load() async {
        do {
            async let accs = accountRepo.fetchAll()
            async let cats = categoryRepo.fetchAll()
            let (fetchedAccounts, fetchedCategories) = try await (accs, cats)
            accounts = fetchedAccounts
            categories = fetchedCategories

            if !hasLoaded {
                hasLoaded = true
                if let entry = editingEntry {
                    selectedType = entry.type
                    amountString = "\(entry.amount)"
                    date = entry.date
                    note = entry.note ?? ""
                    switch entry.type {
                    case .expense:
                        selectedAccount = entry.fromAccount.flatMap { a in accounts.first { $0.id == a.id } }
                    case .income:
                        selectedAccount = entry.toAccount.flatMap { a in accounts.first { $0.id == a.id } }
                    case .transfer:
                        selectedAccount = entry.fromAccount.flatMap { a in accounts.first { $0.id == a.id } }
                        selectedToAccount = entry.toAccount.flatMap { a in accounts.first { $0.id == a.id } }
                    }
                    selectedCategory = entry.category.flatMap { c in categories.first { $0.id == c.id } }
                } else {
                    selectedAccount = accounts.first
                }
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func save() async {
        let now = Date()
        let entry = EntryModel(
            id: editingEntry?.id ?? UUID(),
            date: date,
            type: selectedType,
            amount: amount,
            currency: "RUB",
            note: note.isEmpty ? nil : note,
            tags: editingEntry?.tags,
            isRecurring: editingEntry?.isRecurring ?? false,
            isSoftDeleted: false,
            createdAt: editingEntry?.createdAt ?? now,
            updatedAt: now,
            fromAccount: nil,
            toAccount: nil,
            category: nil
        )
        let from: AccountModel? = selectedType == .income ? nil : selectedAccount
        let to: AccountModel? = selectedType == .expense ? nil : (selectedType == .income ? selectedAccount : selectedToAccount)
        let cat: CategoryModel? = selectedType == .transfer ? nil : selectedCategory
        do { try await entryRepo.save(entry, fromAccount: from, toAccount: to, category: cat) } catch { errorMessage = error.localizedDescription }
    }
}

private extension EntryType {
    var categoryType: CategoryType {
        switch self {
        case .expense: return .expense
        case .income: return .income
        case .transfer: return .expense
        }
    }
}
