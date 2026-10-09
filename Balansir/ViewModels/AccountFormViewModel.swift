import Foundation

@Observable
final class AccountFormViewModel {
    var name = ""
    var selectedType = AccountType.debit
    var initialBalanceString = "0"
    var selectedColorHex = "#4A90D9"
    var selectedIcon = "creditcard"

    private var editingAccount: AccountModel?
    private let accountRepo: any AccountRepository

    init(account: AccountModel? = nil, accountRepo: any AccountRepository) {
        self.editingAccount = account
        self.accountRepo = accountRepo
        if let account {
            name = account.name
            selectedType = account.accountType
            initialBalanceString = "\(account.initialBalance)"
            selectedColorHex = account.colorHex
            selectedIcon = account.iconName
        }
    }

    var isEditing: Bool { editingAccount != nil }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    var initialBalance: Decimal { Decimal(string: initialBalanceString) ?? 0 }
    var errorMessage: String?

    func save(existingCount: Int) async {
        let model = AccountModel(
            id: editingAccount?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            initialBalance: initialBalance,
            currency: "RUB",
            colorHex: selectedColorHex,
            iconName: selectedIcon,
            accountType: selectedType,
            sortOrder: editingAccount?.sortOrder ?? Int32(existingCount),
            isArchived: false,
            createdAt: editingAccount?.createdAt ?? Date(),
            updatedAt: Date()
        )
        do { try await accountRepo.save(model) } catch { errorMessage = error.localizedDescription }
    }
}
