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

    private let accountRepo: any AccountRepository
    private let categoryRepo: any CategoryRepository
    private let entryRepo: any EntryRepository

    init(accountRepo: any AccountRepository, categoryRepo: any CategoryRepository, entryRepo: any EntryRepository) {
        self.accountRepo = accountRepo
        self.categoryRepo = categoryRepo
        self.entryRepo = entryRepo
    }

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
            if selectedAccount == nil { selectedAccount = accounts.first }
        } catch {}
    }

    func save() async {
        let entry = EntryModel(
            id: UUID(),
            date: date,
            type: selectedType,
            amount: amount,
            currency: "RUB",
            note: note.isEmpty ? nil : note,
            tags: nil,
            isRecurring: false,
            createdAt: Date(),
            fromAccount: nil,
            toAccount: nil,
            category: nil
        )
        let from: AccountModel? = selectedType == .income ? nil : selectedAccount
        let to: AccountModel? = selectedType == .expense ? nil : (selectedType == .income ? selectedAccount : selectedToAccount)
        let cat: CategoryModel? = selectedType == .transfer ? nil : selectedCategory
        do { try await entryRepo.save(entry, fromAccount: from, toAccount: to, category: cat) } catch {}
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
