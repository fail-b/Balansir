import Foundation
import CoreData

@objc(Category)
public class Category: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var categoryType: String
    @NSManaged public var iconName: String
    @NSManaged public var colorHex: String
    @NSManaged public var sortOrder: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var isArchived: Bool
    @NSManaged public var entries: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        NSFetchRequest<Category>(entityName: "Category")
    }
}
