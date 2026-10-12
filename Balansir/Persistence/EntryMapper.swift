import Foundation
import CoreData

extension Entry {
    func toModel() -> EntryModel {
        EntryModel(
            id: id,
            date: date,
            type: EntryType(rawValue: entryType) ?? .expense,
            amount: Decimal(amount),
            currency: currency,
            note: note,
            tags: ((tagSet as? Set<TagEntity>) ?? [])
                .map { $0.toModel() }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending },
            isRecurring: isRecurring,
            isSoftDeleted: isSoftDeleted,
            createdAt: createdAt,
            updatedAt: updatedAt ?? createdAt,
            fromAccount: fromAccount?.toModel(),
            toAccount: toAccount?.toModel(),
            category: category?.toModel()
        )
    }

    func update(from model: EntryModel, context: NSManagedObjectContext) {
        date = model.date
        entryType = model.type.rawValue
        amount = NSDecimalNumber(decimal: model.amount).doubleValue
        currency = model.currency
        note = model.note
        isRecurring = model.isRecurring
        isSoftDeleted = model.isSoftDeleted
        updatedAt = Date()
    }
}
