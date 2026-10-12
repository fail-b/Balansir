import Foundation

protocol TagRepository {
    /// Все теги, **включая скрытые**: по скрытым VM находит тег с тем же именем
    /// и возвращает его вместо создания дубля. Что показывать — решает VM.
    func fetchAll() async throws -> [TagModel]
    /// Создать или обновить (переименовать, вернуть скрытый).
    func save(_ tag: TagModel) async throws
    /// Мягкое скрытие: тег пропадает из карусели шита, операции с ним остаются.
    func archive(_ id: UUID) async throws
}
