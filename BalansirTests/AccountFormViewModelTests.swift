import Testing
import Foundation
@testable import Balansir

@Suite("AccountFormViewModel")
@MainActor
struct AccountFormViewModelTests {

    private func makeAccount(
        type: AccountType = .debit,
        colorHex: String = "#4CAF50",
        initialBalance: Decimal = 500,
        sortOrder: Int32 = 2
    ) -> AccountModel {
        AccountModel(
            id: UUID(), name: "Кошелёк", initialBalance: initialBalance, currency: "RUB",
            colorHex: colorHex, iconName: "wallet.pass", accountType: type,
            sortOrder: sortOrder, isArchived: false, createdAt: Date(), updatedAt: Date()
        )
    }

    // MARK: новый счёт

    @Test func новый_счёт_значения_по_умолчанию() {
        let vm = AccountFormViewModel(accountRepo: MockAccountRepository(), locale: TestLocale.ru)
        #expect(vm.name == "")
        #expect(vm.isEditing == false)
        #expect(vm.canSave == false)
        #expect(vm.selectedKind == .card)
        #expect(vm.selectedColorHex == Theme.Palette.accountHexColors[0])
        #expect(vm.initialBalance == 0)
        #expect(vm.title == String(localized: "New Account"))
        #expect(vm.actionTitle == String(localized: "Add"))
    }

    @Test func canSave_только_с_непустым_названием() {
        let vm = AccountFormViewModel(accountRepo: MockAccountRepository(), locale: TestLocale.ru)
        vm.name = "   "
        #expect(vm.canSave == false)
        vm.name = "Наличные"
        #expect(vm.canSave == true)
    }

    @Test func плейсхолдер_зависит_от_типа() {
        let vm = AccountFormViewModel(accountRepo: MockAccountRepository(), locale: TestLocale.ru)
        #expect(vm.namePlaceholder == String(localized: "E.g., Salary card"))
        vm.selectedKind = .cash
        #expect(vm.namePlaceholder == String(localized: "E.g., Wallet"))
        vm.selectedKind = .deposit
        #expect(vm.namePlaceholder == String(localized: "E.g., Savings"))
    }

    @Test func сегмент_маппится_в_тип_счёта() {
        let vm = AccountFormViewModel(accountRepo: MockAccountRepository(), locale: TestLocale.ru)
        vm.selectedKind = .card
        #expect(vm.accountType == .debit)
        vm.selectedKind = .cash
        #expect(vm.accountType == .cash)
        vm.selectedKind = .deposit
        #expect(vm.accountType == .savings)
    }

    @Test func save_новый_счёт_получает_sortOrder_max_плюс_1() async {
        let repo = MockAccountRepository()
        repo.accounts = [.makeTest(name: "A", sortOrder: 0), .makeTest(name: "B", sortOrder: 4)]
        let vm = AccountFormViewModel(accountRepo: repo, locale: TestLocale.ru)
        vm.name = "  Новый  "
        vm.selectedKind = .cash
        await vm.save()
        let saved = repo.accounts.last
        #expect(repo.accounts.count == 3)
        #expect(saved?.name == "Новый")
        #expect(saved?.sortOrder == 5)
        #expect(saved?.accountType == .cash)
        #expect(saved?.iconName == AccountType.cash.defaultIcon)
    }

    @Test func save_первый_счёт_получает_sortOrder_0() async {
        let repo = MockAccountRepository()
        let vm = AccountFormViewModel(accountRepo: repo, locale: TestLocale.ru)
        vm.name = "Первый"
        await vm.save()
        #expect(repo.accounts.first?.sortOrder == 0)
    }

    @Test func save_отрицательный_баланс_с_копейками() async {
        let repo = MockAccountRepository()
        let vm = AccountFormViewModel(accountRepo: repo, locale: TestLocale.ru)
        vm.name = "Кредитка"
        for key: NumpadKey in [.minus, .digit(1), .digit(5), .digit(0), .digit(0), .separator, .digit(2), .digit(5)] {
            vm.press(key)
        }
        #expect(vm.formattedBalance.normalizedSpaces == "\u{2212}1 500,25")
        await vm.save()
        #expect(repo.accounts.first?.initialBalance == Decimal(string: "-1500.25"))
    }

    // MARK: редактирование

    @Test func редактирование_загружает_поля() {
        let account = makeAccount(type: .cash, colorHex: "#9B59B6", initialBalance: -300)
        let vm = AccountFormViewModel(account: account, accountRepo: MockAccountRepository(), locale: TestLocale.ru)
        #expect(vm.isEditing == true)
        #expect(vm.title == String(localized: "Edit Account"))
        #expect(vm.actionTitle == String(localized: "Save"))
        #expect(vm.name == "Кошелёк")
        #expect(vm.selectedKind == .cash)
        #expect(vm.selectedColorHex == "#9B59B6")
        #expect(vm.initialBalance == -300)
        #expect(vm.formattedBalance.normalizedSpaces == "\u{2212}300")
    }

    @Test func save_редактирование_сохраняет_id_sortOrder_и_иконку() async {
        let existing = makeAccount(sortOrder: 5)
        let repo = MockAccountRepository()
        repo.accounts = [existing, .makeTest(sortOrder: 9)]
        let vm = AccountFormViewModel(account: existing, accountRepo: repo, locale: TestLocale.ru)
        vm.name = "Новое имя"
        await vm.save()
        let saved = repo.accounts.first { $0.id == existing.id }
        #expect(saved?.name == "Новое имя")
        #expect(saved?.sortOrder == 5)
        #expect(saved?.iconName == "wallet.pass")
        #expect(saved?.createdAt == existing.createdAt)
    }

    @Test func кредитка_остаётся_кредиткой_если_сегмент_не_трогали() async {
        let existing = makeAccount(type: .credit)
        let repo = MockAccountRepository()
        repo.accounts = [existing]
        let vm = AccountFormViewModel(account: existing, accountRepo: repo, locale: TestLocale.ru)
        #expect(vm.selectedKind == .card)
        #expect(vm.accountType == .credit)
        vm.selectedKind = .cash
        #expect(vm.accountType == .cash)
        vm.selectedKind = .card   // вернули «Карта» — снова исходный credit
        #expect(vm.accountType == .credit)
    }

    @Test func смена_типа_меняет_иконку_на_иконку_типа() async {
        let existing = makeAccount(type: .debit)
        let repo = MockAccountRepository()
        repo.accounts = [existing]
        let vm = AccountFormViewModel(account: existing, accountRepo: repo, locale: TestLocale.ru)
        vm.selectedKind = .deposit
        await vm.save()
        #expect(repo.accounts.first?.accountType == .savings)
        #expect(repo.accounts.first?.iconName == AccountType.savings.defaultIcon)
    }

    // MARK: палитра

    @Test func цвет_из_палитры_не_дублируется() {
        let vm = AccountFormViewModel(account: makeAccount(colorHex: "#4caf50"), accountRepo: MockAccountRepository(), locale: TestLocale.ru)
        #expect(vm.colorOptions == Theme.Palette.accountHexColors)
        #expect(vm.isSelected("#4CAF50"))
    }

    @Test func цвет_вне_палитры_идёт_первым() {
        let vm = AccountFormViewModel(account: makeAccount(colorHex: "#123456"), accountRepo: MockAccountRepository(), locale: TestLocale.ru)
        #expect(vm.colorOptions.first == "#123456")
        #expect(vm.colorOptions.count == Theme.Palette.accountHexColors.count + 1)
    }

    // MARK: ошибки

    @Test func ошибка_репозитория_устанавливает_errorMessage() async {
        let repo = MockAccountRepository()
        repo.shouldThrow = true
        let vm = AccountFormViewModel(accountRepo: repo, locale: TestLocale.ru)
        vm.name = "Счёт"
        await vm.save()
        #expect(vm.errorMessage != nil)
    }
}
