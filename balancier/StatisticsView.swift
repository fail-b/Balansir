import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
    ) private var allEntries: FetchedResults<Entry>

    @State private var selectedPeriod = Period.month

    enum Period: String, CaseIterable {
        case month = "Месяц"
        case threeMonths = "3 месяца"
        case year = "Год"

        var startDate: Date {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .month: return calendar.date(byAdding: .month, value: -1, to: now)!
            case .threeMonths: return calendar.date(byAdding: .month, value: -3, to: now)!
            case .year: return calendar.date(byAdding: .year, value: -1, to: now)!
            }
        }
    }

    private var periodEntries: [Entry] {
        let start = selectedPeriod.startDate
        return allEntries.filter { $0.date >= start }
    }

    private var totalIncome: Double {
        periodEntries.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        periodEntries.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var categoryExpenses: [(category: Category, total: Double)] {
        let expenses = periodEntries.filter { $0.type == .expense && $0.category != nil }
        var grouped: [UUID: (Category, Double)] = [:]
        for entry in expenses {
            guard let cat = entry.category else { continue }
            grouped[cat.id, default: (cat, 0)].1 += entry.amount
        }
        return grouped.values
            .sorted { $0.1 > $1.1 }
            .map { ($0.0, $0.1) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Период", selection: $selectedPeriod) {
                        ForEach(Period.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    summaryCards

                    if !categoryExpenses.isEmpty {
                        expenseBreakdown
                    } else {
                        ContentUnavailableView(
                            "Нет расходов",
                            systemImage: "chart.pie",
                            description: Text("Добавьте расходы за выбранный период")
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Статистика")
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Доходы",
                amount: totalIncome,
                color: .green,
                icon: "arrow.up.circle.fill"
            )
            SummaryCard(
                title: "Расходы",
                amount: totalExpense,
                color: .red,
                icon: "arrow.down.circle.fill"
            )
        }
        .padding(.horizontal)
    }

    private var expenseBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Расходы по категориям")
                .font(.headline)
                .padding(.horizontal)

            // Donut chart segments
            if totalExpense > 0 {
                DonutChart(items: categoryExpenses, total: totalExpense)
                    .frame(height: 200)
                    .padding(.horizontal)
            }

            // Category list
            LazyVStack(spacing: 0) {
                ForEach(categoryExpenses, id: \.category.id) { item in
                    CategoryStatRow(
                        category: item.category,
                        amount: item.total,
                        total: totalExpense
                    )
                    if item.category.id != categoryExpenses.last?.category.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(amount, format: .currency(code: "RUB"))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct CategoryStatRow: View {
    let category: Category
    let amount: Double
    let total: Double

    private var percentage: Double {
        total > 0 ? amount / total : 0
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: category.iconName)
                        .font(.system(size: 15))
                        .foregroundStyle(category.color)
                }

                Text(category.name)
                    .font(.callout)

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(amount, format: .currency(code: "RUB"))
                        .font(.callout)
                        .fontWeight(.semibold)
                    Text("\(Int(percentage * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(category.color)
                        .frame(width: geo.size.width * percentage, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.leading, 48)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

struct DonutChart: View {
    let items: [(category: Category, total: Double)]
    let total: Double

    private struct Slice: Identifiable {
        let id: UUID
        let color: Color
        let startAngle: Angle
        let endAngle: Angle
    }

    private var slices: [Slice] {
        var result: [Slice] = []
        var cumulative = 0.0
        for item in items {
            let start = cumulative / total
            cumulative += item.total
            let end = cumulative / total
            result.append(Slice(
                id: item.category.id,
                color: item.category.color,
                startAngle: .degrees(start * 360 - 90),
                endAngle: .degrees(end * 360 - 90)
            ))
        }
        return result
    }

    var body: some View {
        ZStack {
            ForEach(slices) { slice in
                DonutSlice(
                    startAngle: slice.startAngle,
                    endAngle: slice.endAngle,
                    color: slice.color
                )
            }
            VStack(spacing: 4) {
                Text(total, format: .currency(code: "RUB"))
                    .font(.system(.callout, design: .rounded, weight: .bold))
                Text("всего")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DonutSlice: View {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2
            let innerRadius = radius * 0.6

            Path { path in
                path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
