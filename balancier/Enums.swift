import Foundation
import SwiftUI

enum EntryType: String, CaseIterable {
    case expense = "expense"
    case income = "income"
    case transfer = "transfer"

    var title: String {
        switch self {
        case .expense: return "Расход"
        case .income: return "Доход"
        case .transfer: return "Перевод"
        }
    }

    var color: Color {
        switch self {
        case .expense: return .red
        case .income: return .green
        case .transfer: return .blue
        }
    }
}

enum AccountType: String, CaseIterable {
    case debit = "debit"
    case credit = "credit"
    case cash = "cash"
    case savings = "savings"

    var title: String {
        switch self {
        case .debit: return "Дебетовая"
        case .credit: return "Кредитная"
        case .cash: return "Наличные"
        case .savings: return "Накопительная"
        }
    }

    var defaultIcon: String {
        switch self {
        case .debit: return "creditcard"
        case .credit: return "creditcard.fill"
        case .cash: return "banknote"
        case .savings: return "building.columns"
        }
    }
}

enum CategoryType: String, CaseIterable {
    case expense = "expense"
    case income = "income"

    var title: String {
        switch self {
        case .expense: return "Расходы"
        case .income: return "Доходы"
        }
    }
}
