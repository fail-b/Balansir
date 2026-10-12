import Foundation

extension TagEntity {
    func toModel() -> TagModel {
        TagModel(
            id: id,
            name: name,
            isArchived: isArchived,
            createdAt: createdAt,
            updatedAt: updatedAt ?? createdAt
        )
    }

    func update(from model: TagModel) {
        name = model.name
        isArchived = model.isArchived
        updatedAt = Date()
    }
}
