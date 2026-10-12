import Foundation

/// Шаг онбординга (§4.9).
enum OnboardingStep: Int, CaseIterable {
    case intro, accounts
}

/// Онбординг (§4.9): приветствие → «Где вы храните деньги?».
/// Счёт сохраняется сразу по «+ Добавить счёт», ✕ — мягкое скрытие (решение владельца 2026-10-12).
@Observable
final class OnboardingViewModel: Identifiable {
    let id = UUID()
    var step: OnboardingStep = .intro
    /// Счета, добавленные в этом онбординге (уже сохранены).
    private(set) var addedAccounts: [AccountModel] = []
    /// Встроенная форма счёта — та же логика, что у шита «Новый счёт» (§4.6).
    private(set) var draft: AccountFormViewModel
    var errorMessage: String?
    /// Онбординг завершён («Готово» или «Пропустить») — экран закрывается.
    private(set) var isFinished = false

    private let accountRepo: any AccountRepository
    private let entryRepo: any EntryRepository

    init(accountRepo: any AccountRepository, entryRepo: any EntryRepository) {
        self.accountRepo = accountRepo
        self.entryRepo = entryRepo
        self.draft = AccountFormViewModel(accountRepo: accountRepo)
    }

    // MARK: - Показ при запуске

    /// Нужно ли показать онбординг при запуске (флаг ещё не стоит).
    /// Не показываем, если уже есть «настоящий» счёт: не базовый «Наличные» и не пустой
    /// (есть начальный баланс или операции) — это пользователь со своими данными.
    /// При ошибке чтения показываем: онбординг безвреден, а ошибку увидит пользователь.
    func needsOnboarding() async -> Bool {
        do {
            async let accounts = accountRepo.fetchAll()
            async let entries = entryRepo.fetchAll()
            return try await Self.needsOnboarding(accounts: accounts, entries: entries)
        } catch {
            errorMessage = error.localizedDescription
            return true
        }
    }

    static func needsOnboarding(accounts: [AccountModel], entries: [EntryModel]) -> Bool {
        let usedIds = Set(entries.filter { !$0.isSoftDeleted }.flatMap { [$0.fromAccount?.id, $0.toAccount?.id] }.compactMap { $0 })
        let hasRealAccount = accounts.contains { account in
            let isEmpty = account.initialBalance == 0 && !usedIds.contains(account.id)
            return !isDefaultAccount(account) && !isEmpty
        }
        return !hasRealAccount
    }

    // MARK: - Счёт по умолчанию («Пропустить»)

    static let defaultAccountName = "Наличные"
    static let defaultAccountType = AccountType.cash
    static let defaultAccountColorHex = "#4CAF50"

    static func isDefaultAccount(_ account: AccountModel) -> Bool {
        account.name == defaultAccountName && account.accountType == defaultAccountType
    }

    // MARK: - Шапка и навигация

    var canGoBack: Bool { step != .intro }

    /// Заполнен ли сегмент прогресса (по одному на шаг).
    func isProgressFilled(_ segment: OnboardingStep) -> Bool {
        segment.rawValue <= step.rawValue
    }

    func start() { step = .accounts }

    func back() { step = .intro }

    // MARK: - Счета

    /// «+ Добавить счёт»: сохранить черновик и начать новый.
    func addAccount() async {
        guard draft.canSave else { return }
        guard let saved = await draft.save() else {
            errorMessage = draft.errorMessage
            draft.errorMessage = nil
            return
        }
        addedAccounts.append(saved)
        draft = AccountFormViewModel(accountRepo: accountRepo)
    }

    /// ✕ у добавленного счёта — мягкое скрытие (операций у него ещё нет).
    func removeAccount(_ id: UUID) async {
        do {
            try await accountRepo.archive(id)
            addedAccounts.removeAll { $0.id == id }
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Завершение

    /// «Готово» доступна, если есть добавленный счёт или заполнено имя в форме
    /// (тогда счёт добавится сам — на тап меньше).
    var canFinish: Bool { !addedAccounts.isEmpty || draft.canSave }

    var finishTitle: String { canFinish ? "Готово" : "Добавьте хотя бы один счёт" }

    func finish() async {
        guard canFinish else { return }
        if draft.canSave {
            await addAccount()
            guard errorMessage == nil else { return }
        }
        isFinished = true
    }

    /// «Пропустить»: если счетов в базе нет совсем — создать «Наличные» (cash, 0 ₽).
    func skip() async {
        do {
            let existing = try await accountRepo.fetchAll()
            if existing.isEmpty {
                let now = Date()
                try await accountRepo.save(AccountModel(
                    id: UUID(),
                    name: Self.defaultAccountName,
                    initialBalance: 0,
                    currency: "RUB",
                    colorHex: Self.defaultAccountColorHex,
                    iconName: Self.defaultAccountType.defaultIcon,
                    accountType: Self.defaultAccountType,
                    sortOrder: 0,
                    isArchived: false,
                    createdAt: now,
                    updatedAt: now
                ))
            }
            isFinished = true
        } catch { errorMessage = error.localizedDescription }
    }

    // MARK: - Пример hero-карточки (шаг 1)

    /// Демо-данные карточки на шаге 1 — не из базы.
    let demoExpense: Decimal = 84_320
    let demoIncome: Decimal = 150_000
    /// Цвета — данные (как `colorHex` категорий), доли — от ширины полосы.
    let demoSegments: [(colorHex: String, fraction: Double)] = [
        ("#FF8C42", 0.31), ("#FF6B6B", 0.18), ("#4ECDC4", 0.14), ("#3F51B5", 0.11),
    ]

    var demoTitle: String {
        "Расходы за " + StatisticsService.monthName(for: Date(), calendar: .current).lowercased()
    }
}
