import SwiftUI

struct AccountCard: View {
    let account: AccountModel
    let balance: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            AppIcon.image(named: account.iconName)
                .font(.title3)
                .foregroundStyle(.white)
            Spacer()
            Text(account.name)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
            Text((balance as NSDecimalNumber).doubleValue, format: .currency(code: account.currency))
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(Theme.Spacing.l)
        .frame(width: 140, height: 90)
        .background(
            (Color(hex: account.colorHex) ?? .blue).gradient,
            in: RoundedRectangle(cornerRadius: Theme.Radius.l)
        )
    }
}
