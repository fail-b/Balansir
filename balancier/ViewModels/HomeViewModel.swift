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
    var errorMessage: String?

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

    var monthDailyAverage: Decimal {
        let cal = Calendar.current
        let today = Date()
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: today))!
        let days = Decimal(max(1, cal.dateComponents([.day], from: monthStart, to: today).day ?? 1))
        return monthExpense / days
    }

    var filteredEntries: [EntryModel] {
        guard let accountId = selectedAccountId else { return allEntries }
        return allEntries.filter { entry in
            switch entry.type {
            case .expense: return entry.fromAccount?.id == accountId
            case .income: return entry.toAccount?.id == accountId
            case .transfer:
                return entry.fromAccount?.id == accountId || entry.toAccount?.id == accountId
            }
        }
    }

    var entriesByDay: [DayGroup] {
        DayGroup.grouped(from: filteredEntries)
    }

    var heroSegments: [CategorySegment] {
        guard monthExpense > 0 else { return [] }
        let cal = Calendar.current
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!

        let monthExpenseEntries = allEntries.filter {
            $0.type == .expense && $0.date >= monthStart
        }

        var catTotals: [String: (name: String, colorHex: String, total: Decimal)] = [:]
        for entry in monthExpenseEntries {
            let key = entry.category?.id.uuidString ?? "uncategorized"
            var existing = catTotals[key] ?? (
                name: entry.category?.name ?? "Прочее",
                colorHex: entry.category?.colorHex ?? "#8E8E93",
                total: Decimal(0)
            )
            existing.total += entry.amount
            catTotals[key] = existing
        }

        let sorted = catTotals.values.sorted { $0.total > $1.total }
        return Array(sorted.prefix(4)).map { cat in
            let fraction = NSDecimalNumber(decimal: cat.total / monthExpense).doubleValue
            let percent = Int((fraction * 100).rounded())
            return CategorySegment(name: cat.name, colorHex: cat.colorHex, fraction: fraction, percent: percent)
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
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: Date()))!
            todayExpense = entries
                .filter { $0.type == .expense && $0.date >= todayStart }
                .reduce(0) { $0 + $1.amount }
            monthExpense = entries
                .filter { $0.type == .expense && $0.date >= monthStart }
                .reduce(0) { $0 + $1.amount }
            monthIncome = entries
                .filter { $0.type == .income && $0.date >= monthStart }
                .reduce(0) { $0 + $1.amount }
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

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo)
    }
}
