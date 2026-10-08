import Foundation

struct CategoryModel: Identifiable, Hashable {
    let id: UUID
    var name: String
    var categoryType: CategoryType
    var colorHex: String
    var iconName: String
    var sortOrder: Int32
    var isArchived: Bool
    let createdAt: Date
}
