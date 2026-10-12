import SwiftUI

/// Сводка рядом со свёрнутым таб-баром (`tabViewBottomAccessory`), см. дизайн-задание §3.
/// Две колонки «подпись над суммой»: основная слева, вторая справа.
/// Стекло и форму капсулы рисует система — здесь только содержимое.
struct TabBarSummary: View {
    let selectedTab: AppTab
    let homeVM: HomeViewModel

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.s) {
            content
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .home, .add:
            if homeVM.isSearchActive && !searchQueryEmpty {
                SummaryColumn(label: "Найдено", value: "\(homeVM.searchResultCount)", isPrimary: true)
                Spacer(minLength: Theme.Spacing.s)
                SummaryColumn(label: "Расходы", value: expenseString(homeVM.searchResultExpense), isPrimary: false)
            } else {
                SummaryColumn(label: "Сегодня", value: expenseString(homeVM.todayExpense), isPrimary: true)
                Spacer(minLength: Theme.Spacing.s)
                SummaryColumn(label: homeVM.currentMonthName, value: expenseString(homeVM.monthExpense), isPrimary: false)
            }
        case .statistics:
            SummaryColumn(label: homeVM.currentMonthName, value: MoneyFormatter.format(homeVM.monthExpense), isPrimary: true)
            Spacer(minLength: Theme.Spacing.s)
            SummaryColumn(label: "В день", value: MoneyFormatter.format(homeVM.monthDailyAverage), isPrimary: false)
        case .accounts:
            SummaryColumn(label: "Всего на счетах", value: MoneyFormatter.balance(homeVM.totalBalance), isPrimary: true)
            Spacer(minLength: 0)
        }
    }

    private var searchQueryEmpty: Bool {
        homeVM.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func expenseString(_ amount: Decimal) -> String {
        "\u{2212}\(MoneyFormatter.format(amount))"
    }

}

/// Колонка сводки: подпись (13, `ink2`) над суммой.
/// Основная — слева, сумма крупная `ink`; вторая — справа, сумма меньше и `ink2`.
private struct SummaryColumn: View {
    let label: String
    let value: String
    let isPrimary: Bool

    var body: some View {
        VStack(alignment: isPrimary ? .leading : .trailing, spacing: Theme.Spacing.xxs) {
            Text(label)
                .font(Theme.Font.summaryLabel)
                .foregroundStyle(Theme.Colors.ink2)
            Text(value)
                .font(isPrimary ? Theme.Font.summaryValue : Theme.Font.summarySecondary)
                .foregroundStyle(isPrimary ? Theme.Colors.ink : Theme.Colors.ink2)
                .minimumScaleFactor(Theme.Size.summaryMinScale)
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}
