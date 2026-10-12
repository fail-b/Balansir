import Foundation

@Observable
final class AddEntryViewModel: Identifiable {
    let id = UUID()
    private(set) var accounts: [AccountModel] = []
    private(set) var categories: [CategoryModel] = []
    private(set) var balances: [UUID: Decimal] = [:]

    var selectedType = EntryType.expense
    /// Ввод суммы с цифровой клавиатуры (правила — в `AmountInput`).
    private(set) var amountInput = AmountInput()
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

    /// Последняя допустимая дата операции — сегодня: операции из будущего пока запрещены
    /// (иначе в выборе месяца на Главной понадобились бы будущие месяцы).
    var latestAllowedDate: Date { Date() }

    /// Дата позже сегодняшнего дня.
    private func isInFuture(_ date: Date, now: Date) -> Bool {
        let cal = Calendar.current
        return cal.startOfDay(for: date) > cal.startOfDay(for: now)
    }
    var amount: Decimal { amountInput.value }

    /// Сумма строкой вида «1234.5» — для тестов и предзаполнения.
    var amountString: String {
        get { amountInput.text }
        set { amountInput.text = newValue }
    }

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
            // Операцию со скрытым счётом/категорией тоже можно отредактировать: подставляем их
            // в списки выбора (только для этой операции), иначе выбор пустой и «Сохранить» неактивна.
            if let entry = editingEntry {
                for account in [entry.fromAccount, entry.toAccount].compactMap({ $0 })
                where !accounts.contains(where: { $0.id == account.id }) {
                    accounts.append(account)
                }
                if let category = entry.category, !categories.contains(where: { $0.id == category.id }) {
                    categories.append(category)
                }
            }
            balances = BalanceService.computeBalances(accounts: accounts, entries: fetchedEntries)

            if !hasLoaded {
                hasLoaded = true
                if let entry = editingEntry {
                    selectedType = entry.type
                    amountInput = AmountInput(decimal: entry.amount)
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

    // MARK: - Ввод суммы (правила §4.7 — в AmountInput)

    func press(_ key: NumpadKey) {
        amountInput.apply(key)
    }

    /// Сумма для показа: «1 234,5».
    var formattedAmount: String { amountInput.formatted }

    func save() async {
        let now = Date()
        guard !isInFuture(date, now: now) else {
            errorMessage = "Дата операции не может быть позже сегодняшнего дня."
            return
        }
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
