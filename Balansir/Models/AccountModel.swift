import Foundation

struct AccountModel: Identifiable, Hashable {
    let id: UUID
    var name: String
    var initialBalance: Decimal
    var currency: String
    var colorHex: String
    var iconName: String
    var accountType: AccountType
    var sortOrder: Int32
    var isArchived: Bool
    let createdAt: Date
    let updatedAt: Date
}
