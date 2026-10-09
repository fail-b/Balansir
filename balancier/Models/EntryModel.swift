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
    var isSoftDeleted: Bool
    let createdAt: Date
    let updatedAt: Date
    var fromAccount: AccountModel?
    var toAccount: AccountModel?
    var category: CategoryModel?
}

extension EntryModel {
    var displayTitle: String {
        switch type {
        case .expense: return category?.name ?? "Расход"
        case .income: return category?.name ?? "Доход"
        case .transfer: return "Перевод"
        }
    }

    // Для переводов возвращает «Откуда → Куда», иначе — имя счёта
    var displayAccount: String {
        switch type {
        case .expense: return fromAccount?.name ?? ""
        case .income: return toAccount?.name ?? ""
        case .transfer:
            let from = fromAccount?.name ?? ""
            let to = toAccount?.name ?? ""
            return "\(from) → \(to)"
        }
    }
}
