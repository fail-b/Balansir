import Foundation

protocol CategoryRepository {
    func fetchAll() async throws -> [CategoryModel]
    func save(_ category: CategoryModel) async throws
    /// Мягкое скрытие (категория пропадает из `fetchAll`, операции с ней остаются).
    func archive(_ id: UUID) async throws
    /// Вернуть скрытую категорию (отмена «Скрыть», §4.5).
    func unarchive(_ id: UUID) async throws
}
