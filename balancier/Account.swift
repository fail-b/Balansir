import Foundation
import CoreData
import SwiftUI

@objc(Account)
public class Account: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var initialBalance: Double
    @NSManaged public var currency: String
    @NSManaged public var colorHex: String
    @NSManaged public var iconName: String
    @NSManaged public var accountType: String
    @NSManaged public var sortOrder: Int32
    @NSManaged public var createdAt: Date
    @NSManaged public var isArchived: Bool
    @NSManaged public var outgoingEntries: NSSet?
    @NSManaged public var incomingEntries: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Account> {
        NSFetchRequest<Account>(entityName: "Account")
    }
}

extension Account: Identifiable {
    var type: AccountType {
        AccountType(rawValue: accountType) ?? .debit
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}
