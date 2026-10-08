import Foundation

extension Category {
    func toModel() -> CategoryModel {
        CategoryModel(
            id: id,
            name: name,
            categoryType: CategoryType(rawValue: categoryType) ?? .expense,
            colorHex: colorHex,
            iconName: iconName,
            sortOrder: sortOrder,
            isArchived: isArchived,
            createdAt: Date()
        )
    }

    func update(from model: CategoryModel) {
        name = model.name
        categoryType = model.categoryType.rawValue
        colorHex = model.colorHex
        iconName = model.iconName
        sortOrder = model.sortOrder
        isArchived = model.isArchived
    }
}
