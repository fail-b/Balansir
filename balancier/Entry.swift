import Foundation
import CoreData
import SwiftUI

@objc(Entry)
public class Entry: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var entryType: String
    @NSManaged public var amount: Double
    @NSManaged public var currency: String
    @NSManaged public var note: String?
    @NSManaged public var tags: String?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var fromAccount: Account?
    @NSManaged public var toAccount: Account?
    @NSManaged public var category: Category?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        NSFetchRequest<Entry>(entityName: "Entry")
    }
}

extension Entry: Identifiable {
    var type: EntryType {
        EntryType(rawValue: entryType) ?? .expense
    }

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

    var displayColor: Color {
        switch type {
        case .expense: return category?.color ?? .red
        case .income: return .green
        case .transfer: return .blue
        }
    }

    var displayIcon: String {
        switch type {
        case .expense: return category?.iconName ?? "arrow.down.circle"
        case .income: return category?.iconName ?? "arrow.up.circle"
        case .transfer: return "arrow.left.arrow.right"
        }
    }

    var amountColor: Color {
        switch type {
        case .expense: return .red
        case .income: return .green
        case .transfer: return .primary
        }
    }

    var formattedAmount: String {
        let value = amount.formatted(.currency(code: currency))
        switch type {
        case .expense: return "−\(value)"
        case .income: return "+\(value)"
        case .transfer: return value
        }
    }
}
