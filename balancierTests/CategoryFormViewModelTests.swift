import Testing
import Foundation
@testable import balancier

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

    @Test func save_новая_категория_sortOrder_равен_количеству_существующих() async {
        let repo = MockCategoryRepository()
        repo.categories = [.makeTest(name: "A"), .makeTest(name: "B"), .makeTest(name: "C")]
        let vm = CategoryFormViewModel(categoryRepo: repo)
        vm.name = "Новая"
        await vm.save()
        #expect(vm.errorMessage == nil)
        #expect(repo.savedCategory?.sortOrder == 3)
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
