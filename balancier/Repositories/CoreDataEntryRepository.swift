import CoreData

final class CoreDataEntryRepository: EntryRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll() async throws -> [EntryModel] {
        try await context.perform {
            let request = Entry.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            return try self.context.fetch(request).map { $0.toModel() }
        }
    }

    func save(_ entry: EntryModel, fromAccount: AccountModel?, toAccount: AccountModel?, category: CategoryModel?) async throws {
        try await context.perform {
            let request = Entry.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
            let entity = (try self.context.fetch(request).first) ?? Entry(context: self.context)
            if entity.isInserted {
                entity.id = entry.id
                entity.createdAt = entry.createdAt
            }
            entity.update(from: entry, context: self.context)

            // Resolve Account/Category relationships by ID
            if let fromId = fromAccount?.id {
                let req = Account.fetchRequest()
                req.predicate = NSPredicate(format: "id == %@", fromId as CVarArg)
                entity.fromAccount = try self.context.fetch(req).first
            } else {
                entity.fromAccount = nil
            }
            if let toId = toAccount?.id {
                let req = Account.fetchRequest()
                req.predicate = NSPredicate(format: "id == %@", toId as CVarArg)
                entity.toAccount = try self.context.fetch(req).first
            } else {
                entity.toAccount = nil
            }
            if let catId = category?.id {
                let req = Category.fetchRequest()
                req.predicate = NSPredicate(format: "id == %@", catId as CVarArg)
                entity.category = try self.context.fetch(req).first
            } else {
                entity.category = nil
            }

            try self.context.save()
        }
    }

    func delete(_ id: UUID) async throws {
        try await context.perform {
            let request = Entry.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                self.context.delete(entity)
                try self.context.save()
            }
        }
    }
}
