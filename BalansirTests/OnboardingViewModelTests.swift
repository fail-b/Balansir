import Testing
import Foundation
@testable import Balansir

@Suite("OnboardingViewModel")
@MainActor
struct OnboardingViewModelTests {

    private func makeVM(
        accounts: [AccountModel] = [],
        entries: [EntryModel] = []
    ) -> (OnboardingViewModel, MockAccountRepository, MockEntryRepository) {
        let accountRepo = MockAccountRepository()
        accountRepo.accounts = accounts
        let entryRepo = MockEntryRepository()
        entryRepo.entries = entries
        return (OnboardingViewModel(accountRepo: accountRepo, entryRepo: entryRepo, locale: TestLocale.ru), accountRepo, entryRepo)
    }

    // MARK: показ при запуске

    @Test func показываем_при_пустой_базе() async {
        let (vm, _, _) = makeVM()
        #expect(await vm.needsOnboarding() == true)
    }

    @Test func не_показываем_если_есть_счёт_с_балансом() async {
        let (vm, _, _) = makeVM(accounts: [.makeTest(name: "Карта", initialBalance: 100)])
        #expect(await vm.needsOnboarding() == false)
    }

    @Test func не_показываем_если_у_счёта_есть_операции() async {
        let card = AccountModel.makeTest(name: "Карта")
        let (vm, _, _) = makeVM(accounts: [card], entries: [.makeTest(type: .expense, amount: 50, from: card)])
        #expect(await vm.needsOnboarding() == false)
    }

    @Test func показываем_если_все_счета_пустые() async {
        let (vm, _, _) = makeVM(accounts: [.makeTest(name: "Карта"), .makeTest(name: "Кошелёк")])
        #expect(await vm.needsOnboarding() == true)
    }

    @Test func базовый_счёт_не_отменяет_онбординг() async {
        let cash = AccountModel.makeTest(name: OnboardingViewModel.defaultAccountName, initialBalance: 500, accountType: .cash)
        let (vm, _, _) = makeVM(accounts: [cash], entries: [.makeTest(type: .income, amount: 10, to: cash)])
        #expect(await vm.needsOnboarding() == true)
    }

    @Test func удалённые_операции_не_считаются() async {
        let card = AccountModel.makeTest(name: "Карта")
        var entry = EntryModel.makeTest(type: .expense, amount: 50, from: card)
        entry.isSoftDeleted = true
        let (vm, _, _) = makeVM(accounts: [card], entries: [entry])
        #expect(await vm.needsOnboarding() == true)
    }

    @Test func ошибка_чтения_показывает_онбординг_и_сообщение() async {
        let (vm, accountRepo, _) = makeVM()
        accountRepo.shouldThrow = true
        #expect(await vm.needsOnboarding() == true)
        #expect(vm.errorMessage != nil)
    }

    // MARK: шаги

    @Test func шаги_и_прогресс() {
        let (vm, _, _) = makeVM()
        #expect(vm.step == .intro)
        #expect(vm.canGoBack == false)
        #expect(vm.isProgressFilled(.intro) && !vm.isProgressFilled(.accounts))
        vm.start()
        #expect(vm.step == .accounts)
        #expect(vm.canGoBack == true)
        #expect(vm.isProgressFilled(.accounts))
        vm.back()
        #expect(vm.step == .intro)
    }

    // MARK: добавление и удаление

    @Test func добавить_счёт_сохраняет_сразу_и_сбрасывает_форму() async {
        let (vm, accountRepo, _) = makeVM()
        vm.draft.name = "  Зарплатная  "
        vm.draft.selectedKind = .deposit
        await vm.addAccount()
        #expect(vm.addedAccounts.count == 1)
        #expect(accountRepo.accounts.count == 1)
        #expect(accountRepo.accounts[0].name == "Зарплатная")
        #expect(accountRepo.accounts[0].accountType == .savings)
        #expect(vm.draft.name == "")
        #expect(vm.draft.selectedKind == .card)
    }

    @Test func пустое_имя_не_сохраняется() async {
        let (vm, accountRepo, _) = makeVM()
        vm.draft.name = "   "
        await vm.addAccount()
        #expect(vm.addedAccounts.isEmpty)
        #expect(accountRepo.accounts.isEmpty)
    }

    @Test func новый_счёт_в_конце_списка() async {
        let (vm, accountRepo, _) = makeVM(accounts: [.makeTest(sortOrder: 4)])
        vm.draft.name = "Карта"
        await vm.addAccount()
        #expect(accountRepo.accounts.last?.sortOrder == 5)
    }

    @Test func удаление_скрывает_счёт() async {
        let (vm, accountRepo, _) = makeVM()
        vm.draft.name = "Карта"
        await vm.addAccount()
        let id = vm.addedAccounts[0].id
        await vm.removeAccount(id)
        #expect(vm.addedAccounts.isEmpty)
        #expect(accountRepo.accounts.first?.isArchived == true)
    }

    @Test func ошибка_сохранения_в_errorMessage() async {
        let (vm, accountRepo, _) = makeVM()
        accountRepo.shouldThrow = true
        vm.draft.name = "Карта"
        await vm.addAccount()
        #expect(vm.addedAccounts.isEmpty)
        #expect(vm.errorMessage != nil)
        #expect(vm.draft.errorMessage == nil)
        #expect(vm.draft.name == "Карта")
    }

    // MARK: «Готово»

    @Test func готово_недоступна_без_счетов() async {
        let (vm, _, _) = makeVM()
        #expect(vm.canFinish == false)
        #expect(vm.finishTitle == String(localized: "Add at least one account"))
        await vm.finish()
        #expect(vm.isFinished == false)
    }

    @Test func готово_с_добавленным_счётом() async {
        let (vm, _, _) = makeVM()
        vm.draft.name = "Карта"
        await vm.addAccount()
        #expect(vm.finishTitle == String(localized: "Done"))
        await vm.finish()
        #expect(vm.isFinished == true)
    }

    @Test func готово_добавляет_заполненную_форму() async {
        let (vm, accountRepo, _) = makeVM()
        vm.draft.name = "Кошелёк"
        #expect(vm.canFinish == true)
        await vm.finish()
        #expect(accountRepo.accounts.map(\.name) == ["Кошелёк"])
        #expect(vm.isFinished == true)
    }

    @Test func готово_не_закрывает_при_ошибке() async {
        let (vm, accountRepo, _) = makeVM()
        accountRepo.shouldThrow = true
        vm.draft.name = "Кошелёк"
        await vm.finish()
        #expect(vm.isFinished == false)
        #expect(vm.errorMessage != nil)
    }

    // MARK: «Пропустить»

    @Test func пропустить_без_счетов_создаёт_наличные() async {
        let (vm, accountRepo, _) = makeVM()
        await vm.skip()
        #expect(vm.isFinished == true)
        #expect(accountRepo.accounts.count == 1)
        let cash = accountRepo.accounts[0]
        #expect(cash.name == String(localized: "Cash"))
        #expect(cash.accountType == .cash)
        #expect(cash.colorHex == "#4CAF50")
        #expect(cash.initialBalance == 0)
        #expect(cash.currency == "RUB")
    }

    @Test func пропустить_с_добавленным_счётом_ничего_не_создаёт() async {
        let (vm, accountRepo, _) = makeVM()
        vm.draft.name = "Карта"
        await vm.addAccount()
        await vm.skip()
        #expect(accountRepo.accounts.map(\.name) == ["Карта"])
        #expect(vm.isFinished == true)
    }

    @Test func пропустить_при_существующих_счетах_ничего_не_создаёт() async {
        let (vm, accountRepo, _) = makeVM(accounts: [.makeTest(name: "Старый")])
        await vm.skip()
        #expect(accountRepo.accounts.map(\.name) == ["Старый"])
    }

    @Test func пропустить_с_ошибкой_не_закрывает() async {
        let (vm, accountRepo, _) = makeVM()
        accountRepo.shouldThrow = true
        await vm.skip()
        #expect(vm.isFinished == false)
        #expect(vm.errorMessage != nil)
    }
}
