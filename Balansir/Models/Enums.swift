import Foundation

enum EntryType: String, CaseIterable {
    case expense = "expense"
    case income = "income"
    case transfer = "transfer"

    var title: String {
        switch self {
        case .expense: return String(localized: "Expense")
        // Ключ отдельный: «Income» без уточнения — это «Доходы» (множественное), а тут «Доход».
        case .income: return String(localized: "entry.type.income", defaultValue: "Income")
        case .transfer: return String(localized: "Transfer")
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
        case .debit: return String(localized: "Debit")
        case .credit: return String(localized: "Credit")
        case .cash: return String(localized: "Cash")
        case .savings: return String(localized: "Savings")
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
        case .expense: return String(localized: "Expenses")
        case .income: return String(localized: "Income")
        }
    }
}
