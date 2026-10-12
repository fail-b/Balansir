import Foundation

protocol AccountRepository {
    func fetchAll() async throws -> [AccountModel]
    func save(_ account: AccountModel) async throws
    /// Мягкое скрытие (счёт пропадает из `fetchAll`, операции остаются).
    func archive(_ id: UUID) async throws
    /// Вернуть скрытый счёт (отмена «Скрыть», §4.5).
    func unarchive(_ id: UUID) async throws
}
