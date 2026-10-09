import SwiftUI

// УСТАРЕЛ: таб-бар теперь нативный (ContentView + TabBarSummary). Файл можно удалить.

/// Плавающий нижний бар: стеклянная капсула вкладок + (при скролле) капсула-сводка
/// + отдельная круглая кнопка «+». Заменяет нативный таб-бар с `tabViewBottomAccessory`,
/// чтобы точно совпасть с макетом (`01-home`, `02-home-scrolled-minibar`).
struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab
    /// Свёрнут ли бар до одной вкладки (при скролле вниз).
    let collapsed: Bool
    let homeVM: HomeViewModel
    let onAdd: () -> Void

    /// Общий namespace для морфинга стеклянных капсул при сворачивании/разворачивании.
    @Namespace private var glassNamespace

    private let barHeight: CGFloat = 62

    private let tabs: [(tab: AppTab, title: String, icon: String)] = [
        (.home, "Главная", AppIcon.tabHome),
        (.transactions, "Операции", AppIcon.tabTransactions),
        (.statistics, "Статистика", AppIcon.tabStatistics),
        (.accounts, "Счета", AppIcon.tabAccounts),
    ]

    var body: some View {
        // Все стеклянные элементы — в одном контейнере: так Liquid Glass рендерится
        // корректно (иначе бар выходит фактически прозрачным и пропускает касания на контент под ним).
        GlassEffectContainer(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                if collapsed {
                    collapsedTabCapsule
                    summaryCapsule
                } else {
                    expandedTabCapsule
                }
                addButton
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: collapsed)
    }

    // MARK: - Вкладки

    private var expandedTabCapsule: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.tab) { item in
                tabButton(item)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        .glassEffect(.regular.tint(Theme.Colors.card.opacity(0.55)), in: Capsule())
        .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
        .glassEffectID("tabs", in: glassNamespace)
    }

    private func tabButton(_ item: (tab: AppTab, title: String, icon: String)) -> some View {
        let isActive = selectedTab == item.tab
        return Button {
            selectedTab = item.tab
        } label: {
            tabLabel(item, active: isActive)
                .foregroundStyle(isActive ? Theme.Colors.accent : Theme.Colors.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.s)
                .background {
                    if isActive {
                        RoundedRectangle(cornerRadius: Theme.Radius.xl)
                            .fill(Theme.Colors.selection)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func tabLabel(_ item: (tab: AppTab, title: String, icon: String), active: Bool) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            AppIcon.image(named: item.icon)
                .font(.system(size: 20, weight: .medium))
            Text(item.title)
                .font(Theme.Font.tabLabel)
        }
    }

    /// Свёрнутое состояние — только активная вкладка (иконка, под ней название).
    private var collapsedTabCapsule: some View {
        let item = tabs.first { $0.tab == selectedTab } ?? tabs[0]
        return VStack(spacing: Theme.Spacing.xs) {
            AppIcon.image(named: item.icon)
                .font(.system(size: 20, weight: .medium))
            Text(item.title)
                .font(Theme.Font.tabLabel)
        }
        .foregroundStyle(Theme.Colors.accent)
        .padding(.horizontal, Theme.Spacing.l)
        .frame(height: barHeight)
        .glassEffect(.regular.tint(Theme.Colors.card.opacity(0.55)), in: Capsule())
        .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
        .glassEffectID("tabs", in: glassNamespace)
    }

    // MARK: - Сводка

    private var summaryCapsule: some View {
        summaryContent
            .padding(.horizontal, Theme.Spacing.l)
            .frame(maxWidth: .infinity)
            .frame(height: barHeight)
            .glassEffect(.regular.tint(Theme.Colors.card.opacity(0.55)), in: Capsule())
            .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
            .glassEffectID("summary", in: glassNamespace)
    }

    @ViewBuilder
    private var summaryContent: some View {
        switch selectedTab {
        case .home, .transactions, .add:
            HStack {
                Text("Сегодня \(expenseString(homeVM.todayExpense))")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink)
                Spacer()
                Text("\(currentMonthName) \(expenseString(homeVM.monthExpense))")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
            }
        case .statistics:
            HStack {
                Text("\(currentMonthName) \(MoneyFormatter.format(homeVM.monthExpense))")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink)
                Spacer()
                Text("В день \(MoneyFormatter.format(homeVM.monthDailyAverage))")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
            }
        case .accounts:
            Text("Всего на счетах \(balanceString(homeVM.totalBalance))")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Colors.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Кнопка «+»

    private var addButton: some View {
        Button(action: onAdd) {
            AppIcon.image(named: AppIcon.add)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: barHeight, height: barHeight)
                .background(Theme.Colors.accent, in: Circle())
                .shadow(color: Theme.Colors.accent.opacity(0.35), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

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
