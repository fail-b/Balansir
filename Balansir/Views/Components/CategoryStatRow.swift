import SwiftUI

/// Строка «По категориям» (§4.4): точка · название · % · сумма, под ней прогресс
/// относительно самой большой категории.
struct CategoryStatRow: View {
    let stat: CategoryStat

    private var color: Color {
        stat.colorHex.flatMap { Color(hex: $0) } ?? Theme.Colors.fallback
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Circle()
                .fill(color)
                .frame(width: Theme.Stats.categoryDot, height: Theme.Stats.categoryDot)
                // Точка по центру первой строки текста.
                .frame(height: Theme.Spacing.xxl)

            VStack(spacing: Theme.Spacing.s) {
                HStack(spacing: Theme.Spacing.s) {
                    Text(stat.name)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Colors.ink)
                        .lineLimit(1)
                    Spacer(minLength: Theme.Spacing.s)
                    Text("\(stat.percent)%")
                        .font(Theme.Font.body.monospacedDigit())
                        .foregroundStyle(Theme.Colors.ink2)
                    Text(MoneyFormatter.format(stat.total))
                        .font(Theme.Font.bodyAmount)
                        .foregroundStyle(Theme.Colors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: Theme.Stats.amountColumnWidth, alignment: .trailing)
                }
                .frame(minHeight: Theme.Spacing.xxl)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.Colors.fill)
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * CGFloat(stat.fraction))
                    }
                }
                .frame(height: Theme.Stats.progressHeight)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
        .accessibilityElement(children: .combine)
    }
}
