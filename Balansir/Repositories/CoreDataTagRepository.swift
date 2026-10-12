import CoreData

final class CoreDataTagRepository: TagRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll() async throws -> [TagModel] {
        try await context.perform {
            let request = TagEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            return try self.context.fetch(request).map { $0.toModel() }
        }
    }

    func save(_ tag: TagModel) async throws {
        try await context.perform {
            let request = TagEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
            let entity = (try self.context.fetch(request).first) ?? TagEntity(context: self.context)
            if entity.isInserted {
                entity.id = tag.id
                entity.createdAt = tag.createdAt
            }
            entity.update(from: tag)
            try self.context.save()
        }
    }

    func archive(_ id: UUID) async throws {
        try await context.perform {
            let request = TagEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                entity.isArchived = true
                entity.updatedAt = Date()
                try self.context.save()
            }
        }
    }
}
