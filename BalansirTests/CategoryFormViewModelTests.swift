import Testing
import Foundation
@testable import Balansir

@Suite("CategoryFormViewModel")
@MainActor
struct CategoryFormViewModelTests {

    @Test func новая_категория_пустые_поля() {
        let vm = CategoryFormViewModel(categoryRepo: MockCategoryRepository())
        #expect(vm.name == "")
        #expect(vm.isEditing == false)
        #expect(vm.canSave == false)
    }

    @Test func canSave_true_когда_название_не_пустое() {
        let vm = CategoryFormViewModel(categoryRepo: MockCategoryRepository())
        vm.name = "Продукты"
        #expect(vm.canSave == true)
    }

    @Test func редактирование_загружает_поля() {
        let category = CategoryModel(
            id: UUID(), name: "Транспорт", categoryType: .expense,
            colorHex: "#3498DB", iconName: "car", sortOrder: 3,
            isArchived: false, createdAt: Date(), updatedAt: Date()
        )
        let vm = CategoryFormViewModel(category: category, categoryRepo: MockCategoryRepository())
        #expect(vm.isEditing == true)
        #expect(vm.name == "Транспорт")
        #expect(vm.selectedType == .expense)
        #expect(vm.selectedColorHex == "#3498DB")
        #expect(vm.selectedIcon == "car")
    }

    @Test func save_новая_категория_в_конец_списка() async {
        let repo = MockCategoryRepository()
        repo.categories = [.makeTest(name: "A", sortOrder: 0), .makeTest(name: "B", sortOrder: 1), .makeTest(name: "C", sortOrder: 2)]
        let vm = CategoryFormViewModel(categoryRepo: repo)
        vm.name = "Новая"
        await vm.save()
        #expect(vm.errorMessage == nil)
        #expect(repo.savedCategory?.sortOrder == 3)
    }

    @Test func save_после_скрытия_sortOrder_не_дублируется() async {
        // Скрыли B (sortOrder 1): осталось 2 категории, но новая должна встать после C (2), а не на 2.
        let b = CategoryModel.makeTest(name: "B", sortOrder: 1)
        let repo = MockCategoryRepository()
        repo.categories = [.makeTest(name: "A", sortOrder: 0), b, .makeTest(name: "C", sortOrder: 2)]
        try? await repo.archive(b.id)
        let vm = CategoryFormViewModel(categoryRepo: repo)
        vm.name = "Новая"
        await vm.save()
        #expect(repo.savedCategory?.sortOrder == 3)
    }

    @Test func save_первая_категория_sortOrder_0() async {
        let repo = MockCategoryRepository()
        let vm = CategoryFormViewModel(categoryRepo: repo)
        vm.name = "Первая"
        await vm.save()
        #expect(repo.savedCategory?.sortOrder == 0)
    }

    @Test func save_редактирование_сохраняет_sortOrder() async {
        let existing = CategoryModel(
            id: UUID(), name: "Старая", categoryType: .expense,
            colorHex: "#000000", iconName: "cart", sortOrder: 7,
            isArchived: false, createdAt: Date(), updatedAt: Date()
        )
        let repo = MockCategoryRepository()
        let vm = CategoryFormViewModel(category: existing, categoryRepo: repo)
        vm.name = "Обновлённая"
        await vm.save()
        #expect(repo.savedCategory?.sortOrder == 7)
        #expect(repo.savedCategory?.name == "Обновлённая")
    }

    @Test func ошибка_репозитория_устанавливает_errorMessage() async {
        let repo = MockCategoryRepository()
        repo.shouldThrow = true
        let vm = CategoryFormViewModel(categoryRepo: repo)
        vm.name = "Категория"
        await vm.save()
        #expect(vm.errorMessage != nil)
    }
}
