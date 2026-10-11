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
    var searchQuery: String = ""
    var isSearchActive: Bool = false
    /// Запрос фокуса на поле поиска (активация жестом): шапка ставит фокус и сбрасывает флаг.
    var shouldFocusSearch: Bool = false
    var errorMessage: String?

    // Строка суммы для числового поиска: без разделителей тысяч, запятая ru_RU, без хвостовых нулей («2400,5»).
    private static let amountSearchFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "ru_RU")
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()

    private let accountRepo: any AccountRepository
    private let categoryRepo: any CategoryRepository
    private let entryRepo: any EntryRepository

    init(accountRepo: any AccountRepository, categoryRepo: any CategoryRepository, entryRepo: any EntryRepository) {
        self.accountRepo = accountRepo
        self.categoryRepo = categoryRepo
        self.entryRepo = entryRepo
    }

    var totalBalance: Decimal {
        accounts.reduce(Decimal(0)) { $0 + (balances[$1.id] ?? 0) }
    }

    /// Название текущего месяца для шапки Главной и сводки таб-бара: «Октябрь».
    var currentMonthName: String {
        StatisticsService.monthName(for: Date(), calendar: .current)
    }

    /// Среднее в день за текущий месяц (сегодняшний день входит в число дней).
    var monthDailyAverage: Decimal {
        StatisticsService.dailyAverage(total: monthExpense, today: Date(), calendar: .current)
    }

    /// Лента с учётом фильтра по счёту (карусель) И поискового запроса.
    var filteredEntries: [EntryModel] {
        let byAccount = allEntries.filter(accountMatches)
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
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
        text.folding(options: [.caseInsensitive, .diacriticInsensitive],
                     locale: Locale(identifier: "ru_RU"))
    }

    // Запрос числовой, если состоит только из цифр, пробелов и запятой.
    private func isNumericQuery(_ query: String) -> Bool {
        !query.isEmpty && query.allSatisfy { $0.isNumber || $0 == " " || $0 == "," }
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
        let amountString = Self.amountSearchFormatter.string(from: entry.amount as NSDecimalNumber) ?? ""
        return amountString.hasPrefix(numericNeedle)
    }

    var entriesByDay: [DayGroup] {
        DayGroup.grouped(from: filteredEntries)
    }

    var heroSegments: [CategorySegment] {
        guard monthExpense > 0 else { return [] }
        let month = StatisticsService.monthInterval(containing: Date(), calendar: .current)
        let totals = StatisticsService.expensesByCategory(in: allEntries, interval: month)
        return totals.prefix(4).map { item in
            let fraction = NSDecimalNumber(decimal: item.total / monthExpense).doubleValue
            return CategorySegment(
                name: item.category?.name ?? "Прочее",
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

            let cal = Calendar.current
            let todayStart = cal.startOfDay(for: Date())
            let month = StatisticsService.monthInterval(containing: Date(), calendar: cal)
            todayExpense = entries
                .filter { $0.type == .expense && $0.date >= todayStart }
                .reduce(0) { $0 + $1.amount }
            monthExpense = StatisticsService.total(of: .expense, in: entries, interval: month)
            monthIncome = StatisticsService.total(of: .income, in: entries, interval: month)
        } catch { errorMessage = error.localizedDescription }
    }

    func delete(entry: EntryModel) async {
        do {
            try await entryRepo.delete(entry.id)
            allEntries.removeAll { $0.id == entry.id }
        } catch { errorMessage = error.localizedDescription }
    }

    func makeAddEntryViewModel(for entry: EntryModel? = nil) -> AddEntryViewModel {
        AddEntryViewModel(entry: entry, accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo)
    }

    func makeAccountFormViewModel(for account: AccountModel? = nil) -> AccountFormViewModel {
        AccountFormViewModel(account: account, accountRepo: accountRepo)
    }
}
