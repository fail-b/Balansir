import Foundation
import SwiftUI

struct DayGroup: Identifiable {
    let date: Date
    let entries: [EntryModel]
    let dayExpense: Decimal
    var id: Date { date }

    /// Группирует операции по дням (от свежих к старым). Сумма дня — только расходы.
    static func grouped(from entries: [EntryModel]) -> [DayGroup] {
        let cal = Calendar.current
        var groups: [Date: [EntryModel]] = [:]
        for entry in entries {
            let day = cal.startOfDay(for: entry.date)
            groups[day, default: []].append(entry)
        }
        return groups.map { day, dayEntries in
            let expense = dayEntries
                .filter { $0.type == .expense }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return DayGroup(
                date: day,
                entries: dayEntries.sorted { $0.date > $1.date },
                dayExpense: expense
            )
        }
        .sorted { $0.date > $1.date }
    }
}

struct CategorySegment: Identifiable {
    let name: String
    let colorHex: String
    let fraction: Double
    let percent: Int
    var id: String { name }
}

/// Пункт выбора месяца в шапке Главной: начало месяца + подпись («Октябрь», «Декабрь 2025»).
struct MonthOption: Identifiable, Hashable {
    let start: Date
    let title: String
    var id: Date { start }
}

@Observable
final class HomeViewModel {
    private(set) var accounts: [AccountModel] = []
    private(set) var categories: [CategoryModel] = []
    private var allEntries: [EntryModel] = []
    private(set) var balances: [UUID: Decimal] = [:]
    private(set) var todayExpense: Decimal = 0
    private(set) var monthExpense: Decimal = 0
    private(set) var monthIncome: Decimal = 0
    var selectedAccountId: UUID? = nil
    /// Месяц, выбранный в шапке (начало месяца). nil — «Все операции»: бесконечная лента, hero — текущий месяц.
    var selectedMonth: Date? = nil
    /// Начала месяцев для выбора: от месяца первой операции до текущего, от свежих к ранним.
    private(set) var monthStarts: [Date] = []
    var searchQuery: String = ""
    var isSearchActive: Bool = false
    /// Запрос фокуса на поле поиска (активация жестом): шапка ставит фокус и сбрасывает флаг.
    var shouldFocusSearch: Bool = false
    var errorMessage: String?
    /// Последняя удалённая операция — пока видна плашка «Удалено · Отменить» (§4.2).
    private(set) var recentlyDeleted: EntryModel?

    // Строка суммы для числового поиска: без разделителей тысяч, десятичный разделитель локали,
    // без хвостовых нулей («2400,5» в ru, «2400.5» в en).
    private let amountSearchFormatter: NumberFormatter

    private let accountRepo: any AccountRepository
    private let categoryRepo: any CategoryRepository
    private let entryRepo: any EntryRepository
    /// Только для шита операции (`makeAddEntryViewModel`); теги ленты приходят в `EntryModel.tags`.
    private let tagRepo: any TagRepository
    /// Локаль названий месяцев и чисел в поиске (DI: в тестах — явная).
    private let locale: Locale

    init(accountRepo: any AccountRepository, categoryRepo: any CategoryRepository, entryRepo: any EntryRepository,
         tagRepo: any TagRepository, locale: Locale = .current) {
        self.accountRepo = accountRepo
        self.categoryRepo = categoryRepo
        self.entryRepo = entryRepo
        self.tagRepo = tagRepo
        self.locale = locale
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = locale
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        amountSearchFormatter = f
    }

    var totalBalance: Decimal {
        BalanceService.total(of: accounts, balances: balances)
    }

    // MARK: - Переход со вкладки «Счета» (§4.5)

    /// Счёт, к которому View прокручивает карусель (и ленту — в начало). View сбрасывает через `didRevealAccount()`.
    private(set) var accountToReveal: UUID?

    /// Тап по счёту на вкладке «Счета»: фильтр по нему (без переключения, в отличие от тапа по чипу),
    /// открытый поиск закрывается — иначе фильтр не виден.
    func showAccount(_ id: UUID) {
        selectedAccountId = id
        searchQuery = ""
        isSearchActive = false
        shouldFocusSearch = false
        accountToReveal = id
    }

    func didRevealAccount() {
        accountToReveal = nil
    }

    /// Название текущего месяца для шапки Главной и сводки таб-бара: «Октябрь».
    var currentMonthName: String {
        StatisticsService.monthName(for: Date(), calendar: .current, locale: locale)
    }

    // Месяц внутри фразы «Расходы за октябрь» — регистр как в локали.
    private var currentMonthInPhrase: String {
        StatisticsService.monthNameInPhrase(for: Date(), calendar: .current, locale: locale)
    }

    // MARK: - Выбор месяца (§4.1)

    /// Пункты списка месяцев в шапке (без «Все операции» — его добавляет View первым пунктом).
    var monthOptions: [MonthOption] {
        let now = Date()
        return monthStarts.map {
            MonthOption(start: $0, title: StatisticsService.monthTitle(for: $0, now: now, calendar: .current, locale: locale))
        }
    }

    /// Заголовок шапки: выбранный месяц или «Все операции».
    var headerTitle: String {
        guard let month = selectedMonth else { return String(localized: "All transactions") }
        return StatisticsService.monthTitle(for: month, now: Date(), calendar: .current, locale: locale)
    }

    /// Месяц сводки hero: выбранный, без фильтра — текущий.
    private var heroInterval: DateInterval {
        StatisticsService.monthInterval(containing: selectedMonth ?? Date(), calendar: .current)
    }

    var heroExpense: Decimal {
        StatisticsService.total(of: .expense, in: allEntries, interval: heroInterval)
    }

    var heroIncome: Decimal {
        StatisticsService.total(of: .income, in: allEntries, interval: heroInterval)
    }

    /// Подписи hero: без фильтра месяц не виден в шапке («Все операции») — пишем его в подписи.
    var heroExpenseTitle: String {
        selectedMonth == nil ? String(localized: "Expenses in \(currentMonthInPhrase)") : String(localized: "Expenses")
    }

    var heroIncomeTitle: String {
        selectedMonth == nil ? String(localized: "Income in \(currentMonthInPhrase)") : String(localized: "Income")
    }

    /// Текст пустой ленты (вне поиска) с учётом фильтров счёта и месяца.
    var emptyFeedMessage: String {
        let byMonth = selectedMonth != nil && !isSearchActive
        switch (selectedAccountId != nil, byMonth) {
        case (true, true): return String(localized: "No transactions for this account this month.")
        case (false, true): return String(localized: "No transactions this month.")
        case (true, false): return String(localized: "No transactions for this account.")
        case (false, false): return String(localized: "No transactions yet. Tap “+” to add your first one.")
        }
    }

    // Подходит ли операция под выбранный месяц. В поиске фильтр месяца не действует — ищем по всей истории.
    private func monthMatches(_ entry: EntryModel) -> Bool {
        guard !isSearchActive, let month = selectedMonth else { return true }
        let interval = StatisticsService.monthInterval(containing: month, calendar: .current)
        return entry.date >= interval.start && entry.date < interval.end
    }

    /// Среднее в день за текущий месяц (сегодняшний день входит в число дней).
    var monthDailyAverage: Decimal {
        StatisticsService.dailyAverage(total: monthExpense, today: Date(), calendar: .current)
    }

    /// Лента с учётом фильтра по счёту (карусель), месяца (шапка) И поискового запроса.
    var filteredEntries: [EntryModel] {
        let byAccount = allEntries.filter { accountMatches($0) && monthMatches($0) }
        var query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        // Заметка в ленте показана как «#заметка» — запрос с «#» ищет так же, как без него.
        if query.hasPrefix("#") { query = String(query.dropFirst()).trimmingCharacters(in: .whitespaces) }
        guard !query.isEmpty else { return byAccount }

        let needle = normalize(query)
        let numericNeedle = isNumericQuery(query) ? query.replacingOccurrences(of: " ", with: "") : nil
        return byAccount.filter { entry in
            textMatches(entry, needle: needle)
                || (numericNeedle.map { amountMatches(entry, numericNeedle: $0) } ?? false)
        }
    }

    /// Количество найденных операций (для сводки в таб-баре в режиме поиска).
    var searchResultCount: Int { filteredEntries.count }

    /// Сумма расходов среди найденного (для сводки в таб-баре).
    var searchResultExpense: Decimal {
        filteredEntries
            .filter { $0.type == .expense }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    // Подходит ли операция под выбранный в карусели счёт (nil — все).
    private func accountMatches(_ entry: EntryModel) -> Bool {
        guard let accountId = selectedAccountId else { return true }
        switch entry.type {
        case .expense: return entry.fromAccount?.id == accountId
        case .income: return entry.toAccount?.id == accountId
        case .transfer:
            return entry.fromAccount?.id == accountId || entry.toAccount?.id == accountId
        }
    }

    // Нормализация запроса/текста: без учёта регистра и диакритики (ё = е).
    private func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: locale)
    }

    // Запрос числовой, если состоит только из цифр, пробелов и десятичного разделителя локали.
    private func isNumericQuery(_ query: String) -> Bool {
        let separator = Character(locale.decimalSeparator ?? ",")
        return !query.isEmpty && query.allSatisfy { $0.isNumber || $0 == " " || $0 == separator }
    }

    // Поиск по категории, счёту (у перевода — по обоим) и заметке.
    private func textMatches(_ entry: EntryModel, needle: String) -> Bool {
        var fields: [String] = []
        if let category = entry.category?.name { fields.append(category) }
        if let from = entry.fromAccount?.name { fields.append(from) }
        if let to = entry.toAccount?.name { fields.append(to) }
        if let note = entry.note { fields.append(note) }
        return fields.contains { normalize($0).contains(needle) }
    }

    // Числовой поиск по сумме: сравнение по префиксу строки суммы без разделителей.
    private func amountMatches(_ entry: EntryModel, numericNeedle: String) -> Bool {
        let amountString = amountSearchFormatter.string(from: entry.amount as NSDecimalNumber) ?? ""
        return amountString.hasPrefix(numericNeedle)
    }

    var entriesByDay: [DayGroup] {
        DayGroup.grouped(from: filteredEntries)
    }

    var heroSegments: [CategorySegment] {
        let expense = heroExpense
        guard expense > 0 else { return [] }
        let totals = StatisticsService.expensesByCategory(in: allEntries, interval: heroInterval)
        return totals.prefix(4).map { item in
            let fraction = NSDecimalNumber(decimal: item.total / expense).doubleValue
            return CategorySegment(
                name: item.category?.name ?? String(localized: "Other"),
                colorHex: item.category?.colorHex ?? "#8E8E93",
                fraction: fraction,
                percent: Int((fraction * 100).rounded())
            )
        }
    }

    var heroRemainder: Double {
        max(0.0, 1.0 - heroSegments.reduce(0.0) { $0 + $1.fraction })
    }

    var heroLegend: [CategorySegment] {
        Array(heroSegments.prefix(3))
    }

    func load() async {
        do {
            async let a = accountRepo.fetchAll()
            async let c = categoryRepo.fetchAll()
            async let e = entryRepo.fetchAll()
            let (accs, cats, entries) = try await (a, c, e)
            accounts = accs
            categories = cats
            allEntries = entries
            balances = BalanceService.computeBalances(accounts: accs, entries: entries)
            // Счёт фильтра скрыли на вкладке «Счета» — снимаем фильтр, иначе лента пустая.
            if let id = selectedAccountId, !accs.contains(where: { $0.id == id }) {
                selectedAccountId = nil
            }

            let cal = Calendar.current
            let todayStart = cal.startOfDay(for: Date())
            let month = StatisticsService.monthInterval(containing: Date(), calendar: cal)
            todayExpense = entries
                .filter { $0.type == .expense && $0.date >= todayStart }
                .reduce(0) { $0 + $1.amount }
            monthExpense = StatisticsService.total(of: .expense, in: entries, interval: month)
            monthIncome = StatisticsService.total(of: .income, in: entries, interval: month)
            monthStarts = StatisticsService.monthStarts(covering: entries.map(\.date), now: Date(), calendar: cal)
        } catch { errorMessage = error.localizedDescription }
    }

    /// Удаляет операцию и пересчитывает ленту, балансы и сводку. `false` — удалить не удалось.
    @discardableResult
    func delete(entry: EntryModel) async -> Bool {
        do {
            try await entryRepo.delete(entry.id)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
        recentlyDeleted = entry
        await load()
        return true
    }

    /// «Отменить» на плашке: возвращает последнюю удалённую операцию.
    func undoDelete() async {
        guard let entry = recentlyDeleted else { return }
        recentlyDeleted = nil
        do {
            try await entryRepo.restore(entry.id)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        await load()
    }

    /// Плашка отмены скрыта (истекло время или начато другое действие).
    func dismissUndo() {
        recentlyDeleted = nil
    }

    func makeAddEntryViewModel(for entry: EntryModel? = nil) -> AddEntryViewModel {
        AddEntryViewModel(entry: entry, accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo,
                          tagRepo: tagRepo, locale: locale)
    }

    func makeAccountFormViewModel(for account: AccountModel? = nil) -> AccountFormViewModel {
        AccountFormViewModel(account: account, accountRepo: accountRepo, locale: locale)
    }

    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(accountRepo: accountRepo, entryRepo: entryRepo, locale: locale)
    }
}
