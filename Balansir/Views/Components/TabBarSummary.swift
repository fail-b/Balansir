import SwiftUI

/// Сводка рядом со свёрнутым таб-баром (`tabViewBottomAccessory`), см. ТЗ §3 и `02-home-scrolled-minibar`.
/// Стекло и форму капсулы рисует система — здесь только содержимое.
struct TabBarSummary: View {
    let selectedTab: AppTab
    let homeVM: HomeViewModel

    var body: some View {
        content
            .font(Theme.Font.caption)
            .monospacedDigit()
            .lineLimit(1)
            .padding(.horizontal, Theme.Spacing.l)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .home, .transactions, .add:
            HStack {
                Text("Сегодня \(expenseString(homeVM.todayExpense))")
                    .foregroundStyle(Theme.Colors.ink)
                Spacer(minLength: Theme.Spacing.s)
                Text("\(currentMonthName) \(expenseString(homeVM.monthExpense))")
                    .foregroundStyle(Theme.Colors.ink2)
            }
        case .statistics:
            HStack {
                Text("\(currentMonthName) \(MoneyFormatter.format(homeVM.monthExpense))")
                    .foregroundStyle(Theme.Colors.ink)
                Spacer(minLength: Theme.Spacing.s)
                Text("В день \(MoneyFormatter.format(homeVM.monthDailyAverage))")
                    .foregroundStyle(Theme.Colors.ink2)
            }
        case .accounts:
            Text("Всего на счетах \(balanceString(homeVM.totalBalance))")
                .foregroundStyle(Theme.Colors.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var currentMonthName: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL"
        f.locale = Locale(identifier: "ru_RU")
        let s = f.string(from: Date())
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    private func expenseString(_ amount: Decimal) -> String {
        "\u{2212}\(MoneyFormatter.format(amount))"
    }

    private func balanceString(_ amount: Decimal) -> String {
        amount < 0 ? "\u{2212}\(MoneyFormatter.format(amount))" : MoneyFormatter.format(amount)
    }
}
