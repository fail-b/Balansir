import CoreData

final class CoreDataAccountRepository: AccountRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func fetchAll() async throws -> [AccountModel] {
        try await context.perform {
            let request = Account.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
            request.predicate = NSPredicate(format: "isArchived == NO")
            return try self.context.fetch(request).map { $0.toModel() }
        }
    }

    func save(_ account: AccountModel) async throws {
        try await context.perform {
            let request = Account.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", account.id as CVarArg)
            let entity = (try self.context.fetch(request).first) ?? Account(context: self.context)
            if entity.isInserted {
                entity.id = account.id
                entity.createdAt = account.createdAt
            }
            entity.update(from: account)
            try self.context.save()
        }
    }

    func archive(_ id: UUID) async throws {
        try await context.perform {
            let request = Account.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let entity = try self.context.fetch(request).first {
                entity.isArchived = true
                try self.context.save()
            }
        }
    }
}
