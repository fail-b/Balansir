import Foundation

protocol EntryRepository {
    func fetchAll() async throws -> [EntryModel]
    func save(_ entry: EntryModel, fromAccount: AccountModel?, toAccount: AccountModel?, category: CategoryModel?) async throws
    func delete(_ id: UUID) async throws
}
