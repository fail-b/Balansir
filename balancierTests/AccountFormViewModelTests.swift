import Testing
import Foundation
@testable import balancier

@Suite("AccountFormViewModel")
@MainActor
struct AccountFormViewModelTests {

    @Test func новый_счёт_пустые_поля() {
        let vm = AccountFormViewModel(accountRepo: MockAccountRepository())
        #expect(vm.name == "")
        #expect(vm.isEditing == false)
        #expect(vm.canSave == false)
    }

    @Test func canSave_true_когда_название_не_пустое() {
        let vm = AccountFormViewModel(accountRepo: MockAccountRepository())
        vm.name = "Наличные"
        #expect(vm.canSave == true)
    }

    @Test func редактирование_загружает_поля() {
        let account = AccountModel(
            id: UUID(), name: "Кошелёк", initialBalance: 500, currency: "RUB",
            colorHex: "#FF5733", iconName: "wallet.pass", accountType: .cash,
            sortOrder: 2, isArchived: false, createdAt: Date(), updatedAt: Date()
        )
        let vm = AccountFormViewModel(account: account, accountRepo: MockAccountRepository())
        #expect(vm.isEditing == true)
        #expect(vm.name == "Кошелёк")
        #expect(vm.selectedType == .cash)
        #expect(vm.selectedColorHex == "#FF5733")
        #expect(vm.selectedIcon == "wallet.pass")
    }

    @Test func save_создаёт_новый_счёт() async {
        let repo = MockAccountRepository()
        let vm = AccountFormViewModel(accountRepo: repo)
        vm.name = "Дебетовая"
        vm.selectedType = .debit
        await vm.save(existingCount: 2)
        #expect(repo.accounts.count == 1)
        #expect(repo.accounts[0].name == "Дебетовая")
        #expect(repo.accounts[0].sortOrder == 2)
    }

    @Test func save_редактирование_сохраняет_id_и_sortOrder() async {
        let existing = AccountModel(
            id: UUID(), name: "Старый", initialBalance: 0, currency: "RUB",
            colorHex: "#000000", iconName: "creditcard", accountType: .debit,
            sortOrder: 5, isArchived: false, createdAt: Date(), updatedAt: Date()
        )
        let repo = MockAccountRepository()
        repo.accounts = [existing]
        let vm = AccountFormViewModel(account: existing, accountRepo: repo)
        vm.name = "Новое имя"
        await vm.save(existingCount: 10)
        #expect(repo.accounts[0].id == existing.id)
        #expect(repo.accounts[0].name == "Новое имя")
        // при редактировании sortOrder берётся из оригинала, не из existingCount
        #expect(repo.accounts[0].sortOrder == 5)
    }

    @Test func ошибка_репозитория_устанавливает_errorMessage() async {
        let repo = MockAccountRepository()
        repo.shouldThrow = true
        let vm = AccountFormViewModel(accountRepo: repo)
        vm.name = "Счёт"
        await vm.save(existingCount: 0)
        #expect(vm.errorMessage != nil)
    }
}
