import Foundation

protocol AccountRepository {
    func fetchAll() async throws -> [AccountModel]
    func save(_ account: AccountModel) async throws
    func archive(_ id: UUID) async throws
}
