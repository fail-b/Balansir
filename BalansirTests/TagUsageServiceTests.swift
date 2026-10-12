import Testing
import Foundation
@testable import Balansir

@Suite("TagUsageService")
@MainActor
struct TagUsageServiceTests {

    @Test func сначала_частые_с_категорией_потом_частые_вообще_потом_по_имени() {
        let car = CategoryModel.makeTest(name: "Машина")
        let services = CategoryModel.makeTest(name: "Услуги")
        let fuel = TagModel.makeTest(name: "Бензин")
        let wash = TagModel.makeTest(name: "Мойка")
        let therapy = TagModel.makeTest(name: "Терапия")
        let coffee = TagModel.makeTest(name: "Кофе")
        let entries = [
            EntryModel.makeTest(type: .expense, amount: 1, category: car, tags: [wash]),
            EntryModel.makeTest(type: .expense, amount: 1, category: car, tags: [fuel]),
            EntryModel.makeTest(type: .expense, amount: 1, category: car, tags: [fuel]),
            EntryModel.makeTest(type: .expense, amount: 1, category: services, tags: [therapy]),
            EntryModel.makeTest(type: .expense, amount: 1, category: services, tags: [therapy]),
            EntryModel.makeTest(type: .expense, amount: 1, category: services, tags: [therapy]),
        ]
        let result = TagUsageService.ordered([coffee, therapy, wash, fuel], entries: entries, category: car)
        #expect(result.map(\.name) == ["Бензин", "Мойка", "Терапия", "Кофе"])
    }

    @Test func без_категории_по_общей_частоте() {
        let a = TagModel.makeTest(name: "А")
        let b = TagModel.makeTest(name: "Б")
        let entries = [EntryModel.makeTest(type: .income, amount: 1, tags: [b])]
        #expect(TagUsageService.ordered([a, b], entries: entries, category: nil).map(\.name) == ["Б", "А"])
    }

    @Test func удалённые_операции_не_считаются() {
        let category = CategoryModel.makeTest()
        let a = TagModel.makeTest(name: "А")
        let b = TagModel.makeTest(name: "Б")
        var deleted = EntryModel.makeTest(type: .expense, amount: 1, category: category, tags: [b])
        deleted.isSoftDeleted = true
        #expect(TagUsageService.ordered([b, a], entries: [deleted], category: category).map(\.name) == ["А", "Б"])
    }

    @Test func два_тега_у_операции_считаются_оба() {
        let category = CategoryModel.makeTest()
        let a = TagModel.makeTest(name: "А")
        let b = TagModel.makeTest(name: "Б")
        let c = TagModel.makeTest(name: "В")
        let entries = [EntryModel.makeTest(type: .expense, amount: 1, category: category, tags: [b, c])]
        #expect(TagUsageService.ordered([a, b, c], entries: entries, category: category).map(\.name) == ["Б", "В", "А"])
    }

    @Test func имена_сравниваются_без_регистра_и_пробелов() {
        #expect(TagUsageService.sameName("бензин ", "Бензин", locale: TestLocale.ru))
        #expect(!TagUsageService.sameName("Бензин", "Бензин 95", locale: TestLocale.ru))
        #expect(TagUsageService.cleanName("  Кофе \n") == "Кофе")
    }
}
