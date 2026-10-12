import SwiftUI

struct StatisticsView: View {
    @Bindable var viewModel: StatisticsViewModel
    @Binding var isScrolled: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                    monthCard

                    if !viewModel.categoryStats.isEmpty {
                        categoriesSection
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .background(Theme.Colors.background)
            .clearsBottomAccessory()
            .reportsScroll(to: $isScrolled)
            .navigationTitle("Statistics")
            .task { await viewModel.load() }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Карточка месяца

    private var monthCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(viewModel.monthTitle)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
                Text(MoneyFormatter.format(viewModel.monthExpense))
                    .font(Theme.Font.heroAmount)
                    .tracking(Theme.Font.Tracking.heroAmount)
                    .foregroundStyle(Theme.Colors.ink)
                Text("Avg. \(MoneyFormatter.format(viewModel.dailyAverage)) per day")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
            }

            DailyExpenseChart(bars: viewModel.dayBars)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.hero))
    }

    // MARK: - По категориям

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("By category")
                .font(Theme.Font.headline)
                .foregroundStyle(Theme.Colors.ink)
                .padding(.leading, Theme.Spacing.xs)

            VStack(spacing: 0) {
                ForEach(viewModel.categoryStats) { stat in
                    CategoryStatRow(stat: stat)
                    if stat.id != viewModel.categoryStats.last?.id {
                        Rectangle()
                            .fill(Theme.Colors.separator)
                            .frame(height: Theme.Size.hairline)
                            .padding(.leading, Theme.Stats.separatorInset)
                    }
                }
            }
            .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
    }
}
