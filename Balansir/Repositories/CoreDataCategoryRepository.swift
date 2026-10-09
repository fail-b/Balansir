import CoreData

final class CoreDataCategoryRepository: CategoryRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll() async throws -> [CategoryModel] {
        try await context.perform {
            let request = Category.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
            request.predicate = NSPredicate(format: "isArchived == NO")
            return try self.context.fetch(request).map { $0.toModel() }
        }
    }

    func save(_ category: CategoryModel) async throws {
        try await context.perform {
            let request = Category.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", category.id as CVarArg)
            let entity = (try self.context.fetch(request).first) ?? Category(context: self.context)
            if entity.isInserted {
                entity.id = category.id
                entity.createdAt = category.createdAt
            }
            entity.update(from: category)
            try self.context.save()
        }
    }

    func archive(_ id: UUID) async throws {
        try await context.perform {
            let request = Category.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                entity.isArchived = true
                try self.context.save()
            }
        }
    }
}
