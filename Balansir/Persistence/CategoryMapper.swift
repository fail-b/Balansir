import Foundation

extension Category {
    func toModel() -> CategoryModel {
        let now = Date()
        return CategoryModel(
            id: id,
            name: name,
            categoryType: CategoryType(rawValue: categoryType) ?? .expense,
            colorHex: colorHex,
            iconName: iconName,
            sortOrder: sortOrder,
            isArchived: isArchived,
            createdAt: createdAt ?? now,
            updatedAt: updatedAt ?? createdAt ?? now
        )
    }

    func update(from model: CategoryModel) {
        name = model.name
        categoryType = model.categoryType.rawValue
        colorHex = model.colorHex
        iconName = model.iconName
        sortOrder = model.sortOrder
        isArchived = model.isArchived
        updatedAt = Date()
    }
}
