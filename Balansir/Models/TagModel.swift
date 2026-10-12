import Foundation

/// Тег операции — повторяющееся уточнение категории («Машина» → «Бензин», «Услуги» → «Терапия»).
/// Теги общие, не привязаны к категории. Разовое пояснение — заметка, не тег.
struct TagModel: Identifiable, Hashable {
    let id: UUID
    var name: String
    /// Мягко скрыт: не показывается в карусели шита, на старых операциях остаётся.
    var isArchived: Bool
    let createdAt: Date
    var updatedAt: Date
}
