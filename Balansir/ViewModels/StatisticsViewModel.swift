import Foundation

/// Столбик дня на графике расходов месяца.
struct DayBar: Identifiable, Equatable {
    enum Kind { case past, today, future }

    let day: Int
    let amount: Decimal
    /// Доля от самого большого дня месяца (0…1). Для будущих дней — 0.
    let fraction: Double
    let kind: Kind
    /// Подпись под столбиком (1 · 8 · 15 · 22 · последний день) или nil.
    let axisLabel: String?

    var id: Int { day }
}

/// Строка списка «По категориям».
struct CategoryStat: Identifiable, Equatable {
    let id: UUID?
    let name: String
    /// nil — нет категории, View берёт `Theme.Colors.fallback`.
    let colorHex: String?
    let total: Decimal
    /// Процент от всех расходов месяца, округлённый.
    let percent: Int
    /// Ширина прогресса относительно самой большой категории (0…1).
    let fraction: Double
}

@Observable
final class StatisticsViewModel {
    private(set) var monthTitle = ""
    private(set) var monthExpense: Decimal = 0
    private(set) var dailyAverage: Decimal = 0
    private(set) var dayBars: [DayBar] = []
    private(set) var categoryStats: [CategoryStat] = []
    var errorMessage: String?

    private let entryRepo: any EntryRepository
    private let calendar: Calendar
    private let now: () -> Date

    /// Дни с подписью на оси, кроме последнего дня месяца (он добавляется отдельно).
    private static let axisDays: Set<Int> = [1, 8, 15, 22]

    /// Локаль названия месяца (DI: в тестах — явная).
    private let locale: Locale

    init(entryRepo: any EntryRepository, calendar: Calendar = .current, now: @escaping () -> Date = Date.init,
         locale: Locale = .current) {
        self.entryRepo = entryRepo
        self.calendar = calendar
        self.now = now
        self.locale = locale
    }

    func load() async {
        do {
            let entries = try await entryRepo.fetchAll()
            recalculate(with: entries)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func recalculate(with entries: [EntryModel]) {
        let today = now()
        let month = StatisticsService.monthInterval(containing: today, calendar: calendar)

        let monthName = StatisticsService.monthNameInPhrase(for: today, calendar: calendar, locale: locale)
        monthTitle = String(localized: "Expenses in \(monthName)")

        monthExpense = StatisticsService.total(of: .expense, in: entries, interval: month)
        dailyAverage = StatisticsService.dailyAverage(total: monthExpense, today: today, calendar: calendar)
        dayBars = makeDayBars(entries: entries, month: month, today: today)
        categoryStats = makeCategoryStats(entries: entries, month: month)
    }

    private func makeDayBars(entries: [EntryModel], month: DateInterval, today: Date) -> [DayBar] {
        let daily = StatisticsService.dailyExpenses(in: entries, month: month, calendar: calendar)
        let todayNumber = calendar.component(.day, from: today)
        let maxAmount = daily.prefix(todayNumber).max() ?? 0

        return daily.enumerated().map { index, amount in
            let day = index + 1
            let kind: DayBar.Kind = day < todayNumber ? .past : (day == todayNumber ? .today : .future)
            let fraction = (kind == .future || maxAmount == 0) ? 0 : Self.ratio(amount, maxAmount)
            let isLabeled = Self.axisDays.contains(day) || day == daily.count
            return DayBar(day: day, amount: amount, fraction: fraction, kind: kind,
                          axisLabel: isLabeled ? "\(day)" : nil)
        }
    }

    private func makeCategoryStats(entries: [EntryModel], month: DateInterval) -> [CategoryStat] {
        let totals = StatisticsService.expensesByCategory(in: entries, interval: month)
        guard let maxTotal = totals.first?.total, maxTotal > 0, monthExpense > 0 else { return [] }

        return totals.map { item in
            CategoryStat(
                id: item.category?.id,
                name: item.category?.name ?? String(localized: "No category"),
                colorHex: item.category?.colorHex,
                total: item.total,
                percent: Int((Self.ratio(item.total, monthExpense) * 100).rounded()),
                fraction: Self.ratio(item.total, maxTotal)
            )
        }
    }

    private static func ratio(_ value: Decimal, _ base: Decimal) -> Double {
        NSDecimalNumber(decimal: value / base).doubleValue
    }
}
