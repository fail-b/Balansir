import Foundation

@Observable
final class StatisticsViewModel {
    private(set) var entries: [EntryModel] = []
    var selectedPeriod = StatsPeriod.month

    private let entryRepo: any EntryRepository

    init(entryRepo: any EntryRepository) {
        self.entryRepo = entryRepo
    }

    var periodEntries: [EntryModel] {
        let start = selectedPeriod.startDate
        return entries.filter { $0.date >= start }
    }

    var totalIncome: Decimal {
        periodEntries.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Decimal {
        periodEntries.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var categoryExpenses: [(category: CategoryModel, total: Decimal)] {
        let expenses = periodEntries.filter { $0.type == .expense && $0.category != nil }
        var grouped: [UUID: (CategoryModel, Decimal)] = [:]
        for entry in expenses {
            guard let cat = entry.category else { continue }
            grouped[cat.id, default: (cat, 0)].1 += entry.amount
        }
        return grouped.values.sorted { $0.1 > $1.1 }.map { ($0.0, $0.1) }
    }

    func load() async {
        do { entries = try await entryRepo.fetchAll() } catch {}
    }
}

enum StatsPeriod: String, CaseIterable {
    case month = "Месяц"
    case threeMonths = "3 месяца"
    case year = "Год"

    var startDate: Date {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .month: return cal.date(byAdding: .month, value: -1, to: now)!
        case .threeMonths: return cal.date(byAdding: .month, value: -3, to: now)!
        case .year: return cal.date(byAdding: .year, value: -1, to: now)!
        }
    }
}
