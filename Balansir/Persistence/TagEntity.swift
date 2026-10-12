import Foundation
import CoreData

/// Сущность Core Data «Tag». Класс назван `TagEntity`, а не `Tag`, чтобы не конфликтовать
/// с `Testing.Tag` в тестовом таргете (там `@testable import Balansir` и `import Testing` вместе).
@objc(TagEntity)
public class TagEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var isArchived: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date?
    @NSManaged public var entries: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagEntity> {
        NSFetchRequest<TagEntity>(entityName: "Tag")
    }
}
