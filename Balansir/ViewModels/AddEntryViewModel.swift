import Foundation

@Observable
final class AddEntryViewModel: Identifiable {
    let id = UUID()
    private(set) var accounts: [AccountModel] = []
    private(set) var categories: [CategoryModel] = []
    private(set) var balances: [UUID: Decimal] = [:]

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

    /// Валюта операции = валюта выбранного счёта (символ «₽»/«$»/… зависит от неё).
    var currency: String { selectedAccount?.currency ?? "RUB" }
    var currencySymbol: String { MoneyFormatter.symbol(for: currency) }

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

    func balance(for account: AccountModel) -> Decimal {
        balances[account.id] ?? account.initialBalance
    }

    /// Подпись строки счёта: «Тинькофф · 154 320 ₽».
    func subtitle(for account: AccountModel) -> String {
        "\(account.name) · \(MoneyFormatter.format(balance(for: account), currency: account.currency))"
    }

    func load() async {
        do {
            async let accs = accountRepo.fetchAll()
            async let cats = categoryRepo.fetchAll()
            async let ents = entryRepo.fetchAll()
            let (fetchedAccounts, fetchedCategories, fetchedEntries) = try await (accs, cats, ents)
            accounts = fetchedAccounts
            categories = fetchedCategories
            balances = BalanceService.computeBalances(accounts: fetchedAccounts, entries: fetchedEntries)

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
                    onTypeChanged()
                }
            }
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Смена типа и дефолты

    /// Вызывается при смене сегмента Расход/Доход/Перевод.
    func onTypeChanged() {
        if selectedType == .transfer {
            selectedCategory = nil
            if selectedToAccount == nil || selectedToAccount?.id == selectedAccount?.id {
                selectedToAccount = accounts.first { $0.id != selectedAccount?.id }
            }
        } else {
            if selectedCategory == nil || selectedCategory?.categoryType != selectedType.categoryType {
                selectedCategory = filteredCategories.first
            }
        }
    }

    // MARK: - Ввод суммы (правила §4.7)
    // amountString хранит разделитель как «.» (для Decimal); «,» — только на экране.

    func inputDigit(_ digit: String) {
        if let dotIndex = amountString.firstIndex(of: ".") {
            // дробная часть: не больше 2 знаков
            let fraction = amountString[amountString.index(after: dotIndex)...]
            if fraction.count >= 2 { return }
            amountString += digit
        } else if amountString == "0" {
            amountString = digit            // цифра при «0» заменяет его
        } else {
            if amountString.count >= 9 { return }   // не больше 9 цифр целой части
            amountString += digit
        }
    }

    func inputSeparator() {
        if !amountString.contains(".") { amountString += "." }   // «,» на пустой сумме → «0,»
    }

    func backspace() {
        if amountString.count > 1 {
            amountString.removeLast()
        } else {
            amountString = "0"
        }
    }

    /// Сумма для показа: целая часть группируется пробелами, дробная — через «,».
    var formattedAmount: String {
        let parts = amountString.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intDigits = String(parts[0])
        let grouped = groupThousands(intDigits)
        if amountString.contains(".") {
            let fraction = parts.count > 1 ? String(parts[1]) : ""
            return "\(grouped),\(fraction)"
        }
        return grouped
    }

    private func groupThousands(_ digits: String) -> String {
        guard let number = Int(digits) else { return digits }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: number)) ?? digits
    }

    func save() async {
        let now = Date()
        let entry = EntryModel(
            id: editingEntry?.id ?? UUID(),
            date: date,
            type: selectedType,
            amount: amount,
            currency: currency,
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
