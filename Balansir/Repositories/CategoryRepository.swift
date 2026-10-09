import Foundation

protocol CategoryRepository {
    func fetchAll() async throws -> [CategoryModel]
    func save(_ category: CategoryModel) async throws
    func archive(_ id: UUID) async throws
}
