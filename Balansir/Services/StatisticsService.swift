import Foundation

/// Агрегации операций за месяц — общие для Главной и Статистики.
/// Чистые функции: «сегодня» и календарь передаются параметрами, чтобы считать детерминированно в тестах.
enum StatisticsService {

    /// Сумма по категории. `category == nil` — операции без категории.
    struct CategoryTotal: Equatable {
        let category: CategoryModel?
        let total: Decimal
    }

    /// Календарный месяц, в который попадает дата: [1-е число 00:00; 1-е число следующего месяца).
    static func monthInterval(containing date: Date, calendar: Calendar) -> DateInterval {
        calendar.dateInterval(of: .month, for: date)!
    }

    /// Название месяца с заглавной буквы в именительном падеже: «Октябрь».
    static func monthName(for date: Date, calendar: Calendar, locale: Locale = Locale(identifier: "ru_RU")) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = locale
        f.dateFormat = "LLLL"
        let s = f.string(from: date)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    /// Сумма операций типа `type` внутри интервала.
    static func total(of type: EntryType, in entries: [EntryModel], interval: DateInterval) -> Decimal {
        entries
            .filter { $0.type == type && contains(interval, $0.date) }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// Расходы по дням месяца: элемент 0 — 1-е число, длина = число дней в месяце.
    static func dailyExpenses(in entries: [EntryModel], month: DateInterval, calendar: Calendar) -> [Decimal] {
        let dayCount = calendar.range(of: .day, in: .month, for: month.start)?.count ?? 0
        var result = Array(repeating: Decimal(0), count: dayCount)
        for entry in entries where entry.type == .expense && contains(month, entry.date) {
            let index = calendar.component(.day, from: entry.date) - 1
            guard result.indices.contains(index) else { continue }
            result[index] += entry.amount
        }
        return result
    }

    /// Среднее расходов в день: сумма / прошедшие дни месяца, **включая сегодняшний**
    /// (8 октября → делим на 8).
    static func dailyAverage(total: Decimal, today: Date, calendar: Calendar) -> Decimal {
        let passedDays = calendar.component(.day, from: today)
        return total / Decimal(max(1, passedDays))
    }

    /// Расходы по категориям внутри интервала, по убыванию суммы (при равенстве — по имени).
    static func expensesByCategory(in entries: [EntryModel], interval: DateInterval) -> [CategoryTotal] {
        var totals: [UUID?: (category: CategoryModel?, total: Decimal)] = [:]
        for entry in entries where entry.type == .expense && contains(interval, entry.date) {
            let key = entry.category?.id
            totals[key, default: (entry.category, 0)].total += entry.amount
        }
        return totals.values
            .sorted {
                if $0.total != $1.total { return $0.total > $1.total }
                return ($0.category?.name ?? "") < ($1.category?.name ?? "")
            }
            .map { CategoryTotal(category: $0.category, total: $0.total) }
    }

    // Полуоткрытый интервал: операция в 00:00 следующего месяца сюда не входит.
    private static func contains(_ interval: DateInterval, _ date: Date) -> Bool {
        date >= interval.start && date < interval.end
    }
}
