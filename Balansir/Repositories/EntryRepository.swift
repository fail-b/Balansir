import Foundation

protocol EntryRepository {
    func fetchAll() async throws -> [EntryModel]
    /// Теги берутся из `entry.tags` (по `id`).
    func save(_ entry: EntryModel, fromAccount: AccountModel?, toAccount: AccountModel?, category: CategoryModel?) async throws
    /// Мягкое удаление: операция скрывается, но остаётся в хранилище.
    func delete(_ id: UUID) async throws
    /// Отмена мягкого удаления (плашка «Удалено · Отменить»).
    func restore(_ id: UUID) async throws
}
