import SwiftUI

struct StatisticsView: View {
    @Bindable var viewModel: StatisticsViewModel
    @Binding var isScrolled: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    Picker("Период", selection: $viewModel.selectedPeriod) {
                        ForEach(StatsPeriod.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    summaryCards

                    if !viewModel.categoryExpenses.isEmpty {
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
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .clearsBottomAccessory()
            .reportsScroll(to: $isScrolled)
            .navigationTitle("Статистика")
            .task { await viewModel.load() }
            .alert("Ошибка", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var summaryCards: some View {
        HStack(spacing: Theme.Spacing.m) {
            SummaryCard(title: "Доходы", amount: viewModel.totalIncome, color: Theme.Colors.income, icon: "arrow.up.circle.fill")
            SummaryCard(title: "Расходы", amount: viewModel.totalExpense, color: Theme.Colors.expense, icon: "arrow.down.circle.fill")
        }
        .padding(.horizontal)
    }

    private var expenseBreakdown: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Расходы по категориям").font(.headline).padding(.horizontal)
            if viewModel.totalExpense > 0 {
                DonutChart(items: viewModel.categoryExpenses, total: viewModel.totalExpense)
                    .frame(height: 200)
                    .padding(.horizontal)
            }
            LazyVStack(spacing: 0) {
                ForEach(viewModel.categoryExpenses, id: \.category.id) { item in
                    CategoryStatRow(category: item.category, amount: item.total, total: viewModel.totalExpense)
                    if item.category.id != viewModel.categoryExpenses.last?.category.id {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
            .padding(.horizontal)
        }
    }
}
