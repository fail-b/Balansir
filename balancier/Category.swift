import Foundation
import CoreData
import SwiftUI

@objc(Category)
public class Category: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var categoryType: String
    @NSManaged public var iconName: String
    @NSManaged public var colorHex: String
    @NSManaged public var sortOrder: Int32
    @NSManaged public var isArchived: Bool
    @NSManaged public var entries: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        NSFetchRequest<Category>(entityName: "Category")
    }
}

extension Category: Identifiable {
    var type: CategoryType {
        CategoryType(rawValue: categoryType) ?? .expense
    }

    var color: Color {
        Color(hex: colorHex) ?? .orange
    }
}
