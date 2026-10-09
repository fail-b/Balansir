import Testing
import Foundation
@testable import Balansir

@Suite("TransactionsViewModel")
@MainActor
struct TransactionsViewModelTests {

    private func makeVM(entries: [EntryModel] = []) -> (TransactionsViewModel, MockEntryRepository) {
        let repo = MockEntryRepository()
        repo.entries = entries
        let vm = TransactionsViewModel(
            accountRepo: MockAccountRepository(),
            categoryRepo: MockCategoryRepository(),
            entryRepo: repo
        )
        return (vm, repo)
    }

    // MARK: Загрузка

    @Test func load_заполняет_entries() async {
        let (vm, _) = makeVM(entries: [
            .makeTest(type: .expense, amount: 100),
            .makeTest(type: .income, amount: 200),
        ])
        await vm.load()
        #expect(vm.entries.count == 2)
    }

    @Test func ошибка_репозитория_устанавливает_errorMessage() async {
        let repo = MockEntryRepository()
        repo.shouldThrow = true
        let vm = TransactionsViewModel(
            accountRepo: MockAccountRepository(),
            categoryRepo: MockCategoryRepository(),
            entryRepo: repo
        )
        await vm.load()
        #expect(vm.errorMessage != nil)
    }

    // MARK: Группировка

    @Test func entriesByDay_группирует_по_дням() async {
        let todayEntry1 = EntryModel.makeTest(type: .expense, amount: 100, daysAgo: 0)
        let todayEntry2 = EntryModel.makeTest(type: .income, amount: 200, daysAgo: 0)
        let yesterdayEntry = EntryModel.makeTest(type: .expense, amount: 50, daysAgo: 1)
        let (vm, _) = makeVM(entries: [todayEntry1, todayEntry2, yesterdayEntry])
        await vm.load()

        #expect(vm.entriesByDay.count == 2)
        // первая группа — сегодня (более свежая)
        #expect(vm.entriesByDay[0].entries.count == 2)
        #expect(vm.entriesByDay[1].entries.count == 1)
    }

    // MARK: Сумма дня — только расходы

    @Test func entriesByDay_суммаДня_толькоРасходы() async {
        let (vm, _) = makeVM(entries: [
            .makeTest(type: .expense, amount: 300, daysAgo: 0),
            .makeTest(type: .expense, amount: 100, daysAgo: 0),
            .makeTest(type: .income, amount: 500, daysAgo: 0),
            .makeTest(type: .transfer, amount: 1000, daysAgo: 0),
        ])
        await vm.load()
        #expect(vm.entriesByDay.count == 1)
        #expect(vm.entriesByDay[0].dayExpense == 400)
    }

    // MARK: Поиск

    @Test func поиск_по_названию_категории() async {
        let cat = CategoryModel.makeTest(name: "Продукты")
        let entry1 = EntryModel.makeTest(type: .expense, amount: 100, category: cat)
        let entry2 = EntryModel.makeTest(type: .expense, amount: 50)
        let (vm, _) = makeVM(entries: [entry1, entry2])
        await vm.load()
        vm.searchText = "Продукты"
        #expect(vm.filteredEntries.count == 1)
        #expect(vm.filteredEntries[0].id == entry1.id)
    }

    @Test func поиск_по_заметке() async {
        let entry1 = EntryModel(
            id: UUID(), date: Date(), type: .expense, amount: 100, currency: "RUB",
            note: "кофе с другом", tags: nil, isRecurring: false, isSoftDeleted: false,
            createdAt: Date(), updatedAt: Date(),
            fromAccount: nil, toAccount: nil, category: nil
        )
        let entry2 = EntryModel.makeTest(type: .expense, amount: 50)
        let (vm, _) = makeVM(entries: [entry1, entry2])
        await vm.load()
        vm.searchText = "кофе"
        #expect(vm.filteredEntries.count == 1)
        #expect(vm.filteredEntries[0].id == entry1.id)
    }

    @Test func пустой_поиск_возвращает_все_записи() async {
        let (vm, _) = makeVM(entries: [
            .makeTest(type: .expense, amount: 100),
            .makeTest(type: .income, amount: 200),
        ])
        await vm.load()
        vm.searchText = ""
        #expect(vm.filteredEntries.count == 2)
    }

    // MARK: Удаление

    @Test func delete_удаляет_из_списка() async {
        let entry1 = EntryModel.makeTest(type: .expense, amount: 100)
        let entry2 = EntryModel.makeTest(type: .income, amount: 200)
        let (vm, _) = makeVM(entries: [entry1, entry2])
        await vm.load()
        await vm.delete(entry1)
        #expect(vm.entries.count == 1)
        #expect(vm.entries[0].id == entry2.id)
    }

    @Test func delete_ошибка_устанавливает_errorMessage() async {
        let entry = EntryModel.makeTest(type: .expense, amount: 100)
        let repo = MockEntryRepository()
        repo.entries = [entry]
        let vm = TransactionsViewModel(
            accountRepo: MockAccountRepository(),
            categoryRepo: MockCategoryRepository(),
            entryRepo: repo
        )
        await vm.load()
        repo.shouldThrow = true
        await vm.delete(entry)
        #expect(vm.errorMessage != nil)
    }
}
