import Foundation
import SwiftUI

struct EntryModel: Identifiable {
    let id: UUID
    var date: Date
    var type: EntryType
    var amount: Decimal
    var currency: String
    var note: String?
    var tags: String?
    var isRecurring: Bool
    let createdAt: Date
    var fromAccount: AccountModel?
    var toAccount: AccountModel?
    var category: CategoryModel?
}

extension EntryModel {
    var displayTitle: String {
        switch type {
        case .expense: return category?.name ?? "Расход"
        case .income: return category?.name ?? "Доход"
        case .transfer:
            let from = fromAccount?.name ?? ""
            let to = toAccount?.name ?? ""
            return "\(from) → \(to)"
        }
    }

    var displayAccount: String {
        switch type {
        case .expense: return fromAccount?.name ?? ""
        case .income: return toAccount?.name ?? ""
        case .transfer: return fromAccount?.name ?? ""
        }
    }

    var displayIcon: String {
        switch type {
        case .expense: return category?.iconName ?? "arrow.down.circle"
        case .income: return category?.iconName ?? "arrow.up.circle"
        case .transfer: return "arrow.left.arrow.right"
        }
    }

    var displayColor: Color {
        switch type {
        case .expense: return Theme.Colors.expense
        case .income: return Theme.Colors.income
        case .transfer: return Theme.Colors.transfer
        }
    }

    var amountColor: Color {
        switch type {
        case .expense: return Theme.Colors.expense
        case .income: return Theme.Colors.income
        case .transfer: return .primary
        }
    }

    var formattedAmount: String {
        let value = (amount as NSDecimalNumber).doubleValue
            .formatted(.currency(code: currency))
        switch type {
        case .expense: return "−\(value)"
        case .income: return "+\(value)"
        case .transfer: return value
        }
    }
}
