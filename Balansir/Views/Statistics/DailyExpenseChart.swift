import SwiftUI

/// Столбики расходов по дням месяца (§4.4): прошедшие дни — `ink`, сегодня — `accent`,
/// будущие — `fill` минимальной высоты. Под столбиками — подписи 1 · 8 · 15 · 22 · последний день.
struct DailyExpenseChart: View {
    let bars: [DayBar]

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            HStack(alignment: .bottom, spacing: Theme.Stats.barGap) {
                ForEach(bars) { bar in
                    RoundedRectangle(cornerRadius: Theme.Stats.barRadius)
                        .fill(color(for: bar.kind))
                        .frame(maxWidth: .infinity)
                        .frame(height: height(for: bar))
                }
            }
            .frame(height: Theme.Stats.chartHeight, alignment: .bottom)

            // Подписи в тех же колонках, что и столбики: центр подписи = центр столбика.
            HStack(spacing: Theme.Stats.barGap) {
                ForEach(bars) { bar in
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .overlay {
                            if let label = bar.axisLabel {
                                Text(label)
                                    .font(Theme.Font.time)
                                    .foregroundStyle(Theme.Colors.ink2)
                                    .fixedSize()
                            }
                        }
                }
            }
            .frame(height: Theme.Spacing.l)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily expenses this month")
    }

    private func height(for bar: DayBar) -> CGFloat {
        guard bar.kind != .future else { return Theme.Stats.barMinHeight }
        return max(Theme.Stats.barMinHeight, Theme.Stats.chartHeight * CGFloat(bar.fraction))
    }

    private func color(for kind: DayBar.Kind) -> Color {
        switch kind {
        case .past: Theme.Colors.ink
        case .today: Theme.Colors.accent
        case .future: Theme.Colors.fill
        }
    }
}
