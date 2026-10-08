import Foundation

@Observable
final class CategoryFormViewModel {
    var name = ""
    var selectedType = CategoryType.expense
    var selectedColorHex = "#4A90D9"
    var selectedIcon = "fork.knife"

    private let editingCategory: CategoryModel?
    private let categoryRepo: any CategoryRepository
    var errorMessage: String?

    init(category: CategoryModel? = nil, categoryRepo: any CategoryRepository) {
        self.editingCategory = category
        self.categoryRepo = categoryRepo
        if let category {
            name = category.name
            selectedType = category.categoryType
            selectedColorHex = category.colorHex
            selectedIcon = category.iconName
        }
    }

    var isEditing: Bool { editingCategory != nil }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func save() async {
        do {
            let sortOrder: Int32
            if let existing = editingCategory {
                sortOrder = existing.sortOrder
            } else {
                let all = try await categoryRepo.fetchAll()
                sortOrder = Int32(all.count)
            }
            let model = CategoryModel(
                id: editingCategory?.id ?? UUID(),
                name: name.trimmingCharacters(in: .whitespaces),
                categoryType: selectedType,
                colorHex: selectedColorHex,
                iconName: selectedIcon,
                sortOrder: sortOrder,
                isArchived: false,
                createdAt: editingCategory?.createdAt ?? Date(),
                updatedAt: Date()
            )
            try await categoryRepo.save(model)
        } catch { errorMessage = error.localizedDescription }
    }
}
