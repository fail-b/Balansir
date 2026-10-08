import Testing
import Foundation
@testable import balancier

@Suite("AddEntryViewModel")
@MainActor
struct AddEntryViewModelTests {

    // MARK: canSave

    @Test func перевод_можно_сохранить_при_разных_счетах() async {
        let a1 = AccountModel.makeTest(name: "A1")
        let a2 = AccountModel.makeTest(name: "A2")
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [a1, a2]

        let vm = AddEntryViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: MockEntryRepository())
        await vm.load()
        vm.selectedType = .transfer
        vm.amountString = "500"
        vm.selectedAccount = a1
        vm.selectedToAccount = a2

        #expect(vm.canSave == true)
    }

    @Test func перевод_нельзя_сохранить_при_одинаковых_счетах() async {
        let a1 = AccountModel.makeTest()
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [a1]

        let vm = AddEntryViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: MockEntryRepository())
        await vm.load()
        vm.selectedType = .transfer
        vm.amountString = "500"
        vm.selectedAccount = a1
        vm.selectedToAccount = a1

        #expect(vm.canSave == false)
    }

    @Test func расход_нельзя_сохранить_без_категории() async {
        let account = AccountModel.makeTest()
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]

        let vm = AddEntryViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: MockEntryRepository())
        await vm.load()
        vm.selectedType = .expense
        vm.amountString = "100"
        vm.selectedAccount = account
        vm.selectedCategory = nil

        #expect(vm.canSave == false)
    }

    @Test func нельзя_сохранить_с_нулевой_суммой() async {
        let account = AccountModel.makeTest()
        let category = CategoryModel.makeTest()
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let categoryRepo = MockCategoryRepository()
        categoryRepo.categories = [category]

        let vm = AddEntryViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: MockEntryRepository())
        await vm.load()
        vm.selectedType = .expense
        vm.amountString = "0"
        vm.selectedAccount = account
        vm.selectedCategory = category

        #expect(vm.canSave == false)
    }

    // MARK: save — корректная передача счетов и категории

    @Test func save_расход_передаёт_fromAccount_и_категорию() async {
        let account = AccountModel.makeTest()
        let category = CategoryModel.makeTest(type: .expense)
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let categoryRepo = MockCategoryRepository()
        categoryRepo.categories = [category]
        let entryRepo = MockEntryRepository()

        let vm = AddEntryViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo)
        await vm.load()
        vm.selectedType = .expense
        vm.amountString = "150"
        vm.selectedAccount = account
        vm.selectedCategory = category
        await vm.save()

        #expect(entryRepo.savedFromAccount?.id == account.id)
        #expect(entryRepo.savedToAccount == nil)
        #expect(entryRepo.savedCategory?.id == category.id)
    }

    @Test func save_доход_передаёт_toAccount_и_категорию() async {
        let account = AccountModel.makeTest()
        let category = CategoryModel.makeTest(type: .income)
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let categoryRepo = MockCategoryRepository()
        categoryRepo.categories = [category]
        let entryRepo = MockEntryRepository()

        let vm = AddEntryViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo)
        await vm.load()
        vm.selectedType = .income
        vm.amountString = "300"
        vm.selectedAccount = account
        vm.selectedCategory = category
        await vm.save()

        #expect(entryRepo.savedFromAccount == nil)
        #expect(entryRepo.savedToAccount?.id == account.id)
        #expect(entryRepo.savedCategory?.id == category.id)
    }

    @Test func save_перевод_передаёт_оба_счёта_без_категории() async {
        let a1 = AccountModel.makeTest(name: "A1")
        let a2 = AccountModel.makeTest(name: "A2")
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [a1, a2]
        let entryRepo = MockEntryRepository()

        let vm = AddEntryViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: entryRepo)
        await vm.load()
        vm.selectedType = .transfer
        vm.amountString = "200"
        vm.selectedAccount = a1
        vm.selectedToAccount = a2
        await vm.save()

        #expect(entryRepo.savedFromAccount?.id == a1.id)
        #expect(entryRepo.savedToAccount?.id == a2.id)
        #expect(entryRepo.savedCategory == nil)
    }

    // MARK: edit-режим

    @Test func редактирование_загружает_поля_записи() async {
        let account = AccountModel.makeTest()
        let category = CategoryModel.makeTest()
        let now = Date()
        let entry = EntryModel(
            id: UUID(), date: now, type: .expense, amount: 750, currency: "RUB",
            note: "тест заметка", tags: nil, isRecurring: false, isSoftDeleted: false,
            createdAt: now, updatedAt: now,
            fromAccount: account, toAccount: nil, category: category
        )

        let accountRepo = MockAccountRepository()
        accountRepo.accounts = [account]
        let categoryRepo = MockCategoryRepository()
        categoryRepo.categories = [category]

        let vm = AddEntryViewModel(entry: entry, accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: MockEntryRepository())
        await vm.load()

        #expect(vm.isEditing == true)
        #expect(vm.amount == 750)
        #expect(vm.note == "тест заметка")
        #expect(vm.selectedType == .expense)
        #expect(vm.selectedAccount?.id == account.id)
        #expect(vm.selectedCategory?.id == category.id)
    }

    // MARK: ошибки

    @Test func ошибка_репозитория_устанавливает_errorMessage() async {
        let accountRepo = MockAccountRepository()
        accountRepo.shouldThrow = true

        let vm = AddEntryViewModel(accountRepo: accountRepo, categoryRepo: MockCategoryRepository(), entryRepo: MockEntryRepository())
        await vm.load()

        #expect(vm.errorMessage != nil)
    }
}
