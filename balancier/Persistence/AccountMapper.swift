import Foundation

extension Account {
    func toModel() -> AccountModel {
        AccountModel(
            id: id,
            name: name,
            initialBalance: Decimal(initialBalance),
            currency: currency,
            colorHex: colorHex,
            iconName: iconName,
            accountType: AccountType(rawValue: accountType) ?? .debit,
            sortOrder: sortOrder,
            isArchived: isArchived,
            createdAt: createdAt
        )
    }

    func update(from model: AccountModel) {
        name = model.name
        initialBalance = NSDecimalNumber(decimal: model.initialBalance).doubleValue
        currency = model.currency
        colorHex = model.colorHex
        iconName = model.iconName
        accountType = model.accountType.rawValue
        sortOrder = model.sortOrder
        isArchived = model.isArchived
    }
}
