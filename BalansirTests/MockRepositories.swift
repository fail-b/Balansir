import Foundation
@testable import Balansir

// Основной таргет собран с SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor,
// поэтому модели, протоколы и ViewModel изолированы на главном акторе.
// Тесты и моки тоже должны работать на MainActor, иначе — ошибки компиляции.

@MainActor
final class MockAccountRepository: AccountRepository {
    var accounts: [AccountModel] = []
    var shouldThrow = false

    func fetchAll() async throws -> [AccountModel] {
        if shouldThrow { throw NSError(domain: "test", code: 1) }
        return accounts
    }

    func save(_ account: AccountModel) async throws {
        if shouldThrow { throw NSError(domain: "test", code: 1) }
        if let idx = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[idx] = account
        } else {
            accounts.append(account)
        }
    }

    func archive(_ id: UUID) async throws {
        if shouldThrow { throw NSError(domain: "test", code: 1) }
    }
}

@MainActor
final class MockCategoryRepository: CategoryRepository {
    var categories: [CategoryModel] = []
    var shouldThrow = false
    var savedCategory: CategoryModel?

    func fetchAll() async throws -> [CategoryModel] {
        if shouldThrow { throw NSError(domain: "test", code: 1) }
        return categories
    }

    func save(_ category: CategoryModel) async throws {
        if shouldThrow { throw NSError(domain: "test", code: 1) }
        savedCategory = category
    }

    func archive(_ id: UUID) async throws {
        if shouldThrow { throw NSError(domain: "test", code: 1) }
    }
}

@MainActor
final class MockEntryRepository: EntryRepository {
    var entries: [EntryModel] = []
    var shouldThrow = false
    var savedEntry: EntryModel?
    var savedFromAccount: AccountModel?
    var savedToAccount: AccountModel?
    var savedCategory: CategoryModel?

    func fetchAll() async throws -> [EntryModel] {
        if shouldThrow { throw NSError(domain: "test", code: 1) }
        return entries
    }

    func save(_ entry: EntryModel, fromAccount: AccountModel?, toAccount: AccountModel?, category: CategoryModel?) async throws {
        if shouldThrow { throw NSError(domain: "test", code: 1) }
        savedEntry = entry
        savedFromAccount = fromAccount
        savedToAccount = toAccount
        savedCategory = category
        entries.append(entry)
    }

    func delete(_ id: UUID) async throws {
        if shouldThrow { throw NSError(domain: "test", code: 1) }
        entries.removeAll { $0.id == id }
    }
}

// MARK: - Фабрики тестовых моделей

@MainActor
extension AccountModel {
    static func makeTest(name: String = "Счёт", initialBalance: Decimal = 0) -> AccountModel {
        AccountModel(
            id: UUID(), name: name, initialBalance: initialBalance, currency: "RUB",
            colorHex: "#FF0000", iconName: "creditcard", accountType: .debit,
            sortOrder: 0, isArchived: false, createdAt: Date(), updatedAt: Date()
        )
    }
}

@MainActor
extension CategoryModel {
    static func makeTest(name: String = "Категория", type: CategoryType = .expense) -> CategoryModel {
        CategoryModel(
            id: UUID(), name: name, categoryType: type, colorHex: "#FF0000",
            iconName: "cart", sortOrder: 0, isArchived: false, createdAt: Date(), updatedAt: Date()
        )
    }
}

@MainActor
extension EntryModel {
    static func makeTest(
        type: EntryType,
        amount: Decimal,
        daysAgo: Int = 0,
        from: AccountModel? = nil,
        to: AccountModel? = nil,
        category: CategoryModel? = nil
    ) -> EntryModel {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        return EntryModel(
            id: UUID(), date: date, type: type, amount: amount, currency: "RUB",
            note: nil, tags: nil, isRecurring: false, isSoftDeleted: false,
            createdAt: Date(), updatedAt: Date(),
            fromAccount: from, toAccount: to, category: category
        )
    }
}
