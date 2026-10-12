import Foundation

/// Тип счёта в сегменте шита «Новый счёт» (§4.6). `credit` есть в модели, но в форме не показывается.
enum AccountKind: CaseIterable, Hashable {
    case card, cash, deposit

    init(_ type: AccountType) {
        switch type {
        case .debit, .credit: self = .card
        case .cash: self = .cash
        case .savings: self = .deposit
        }
    }

    var title: String {
        switch self {
        case .card: return String(localized: "Card")
        case .cash: return String(localized: "Cash")
        case .deposit: return String(localized: "Deposit")
        }
    }

    var accountType: AccountType {
        switch self {
        case .card: return .debit
        case .cash: return .cash
        case .deposit: return .savings
        }
    }

    var namePlaceholder: String {
        switch self {
        case .card: return String(localized: "E.g., Salary card")
        case .cash: return String(localized: "E.g., Wallet")
        case .deposit: return String(localized: "E.g., Savings")
        }
    }
}

@Observable
final class AccountFormViewModel: Identifiable {
    let id = UUID()
    var name = ""
    var selectedKind = AccountKind.card
    var selectedColorHex = Theme.Palette.accountHexColors[0]
    var errorMessage: String?
    /// Начальный баланс: копейки и минус (кредитка, долг) — ввод своим numpad.
    private(set) var balanceInput = AmountInput(allowsNegative: true)

    private let editingAccount: AccountModel?
    private let accountRepo: any AccountRepository

    /// Локаль разделителей в поле «Баланс» (DI: в тестах — явная).
    private let locale: Locale

    init(account: AccountModel? = nil, accountRepo: any AccountRepository, locale: Locale = .current) {
        self.locale = locale
        self.editingAccount = account
        self.accountRepo = accountRepo
        if let account {
            name = account.name
            selectedKind = AccountKind(account.accountType)
            selectedColorHex = account.colorHex
            balanceInput = AmountInput(decimal: account.initialBalance, allowsNegative: true)
        }
    }

    var isEditing: Bool { editingAccount != nil }
    var title: String { isEditing ? String(localized: "Edit Account") : String(localized: "New Account") }
    var actionTitle: String { isEditing ? String(localized: "Save") : String(localized: "Add") }
    var namePlaceholder: String { selectedKind.namePlaceholder }
    var canSave: Bool { !trimmedName.isEmpty }

    /// Цвета для выбора. Цвет редактируемого счёта не из палитры — первым в ряду, чтобы он не потерялся.
    var colorOptions: [String] {
        let palette = Theme.Palette.accountHexColors
        let current = selectedColorHex.uppercased()
        return palette.contains(where: { $0.uppercased() == current }) ? palette : [selectedColorHex] + palette
    }

    func isSelected(_ hex: String) -> Bool {
        hex.uppercased() == selectedColorHex.uppercased()
    }

    // MARK: - Баланс

    var initialBalance: Decimal { balanceInput.value }
    var formattedBalance: String { balanceInput.formatted(locale: locale) }
    var isBalanceEmpty: Bool { balanceInput.isEmpty }

    func press(_ key: NumpadKey) {
        balanceInput.apply(key)
    }

    // MARK: - Сохранение

    /// Тип для сохранения: если сегмент не трогали — исходный тип (кредитка остаётся `credit`).
    var accountType: AccountType {
        if let editingAccount, AccountKind(editingAccount.accountType) == selectedKind {
            return editingAccount.accountType
        }
        return selectedKind.accountType
    }

    /// Иконка: при смене типа — иконка нового типа, иначе прежняя.
    private var iconName: String {
        if let editingAccount, editingAccount.accountType == accountType {
            return editingAccount.iconName
        }
        return accountType.defaultIcon
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Сохраняет счёт и возвращает его (онбордингу нужен id для ✕). При ошибке — `nil` и `errorMessage`.
    @discardableResult
    func save() async -> AccountModel? {
        do {
            let sortOrder: Int32
            if let editingAccount {
                sortOrder = editingAccount.sortOrder
            } else {
                // Новый счёт — в конец списка: max + 1 (count даёт дубли после скрытия счетов).
                let all = try await accountRepo.fetchAll()
                sortOrder = (all.map(\.sortOrder).max() ?? -1) + 1
            }
            let model = AccountModel(
                id: editingAccount?.id ?? UUID(),
                name: trimmedName,
                initialBalance: initialBalance,
                currency: editingAccount?.currency ?? "RUB",
                colorHex: selectedColorHex,
                iconName: iconName,
                accountType: accountType,
                sortOrder: sortOrder,
                isArchived: false,
                createdAt: editingAccount?.createdAt ?? Date(),
                updatedAt: Date()
            )
            try await accountRepo.save(model)
            return model
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
