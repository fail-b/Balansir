import Foundation
import CoreData

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
