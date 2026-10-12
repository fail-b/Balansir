import SwiftUI

/// Строка счёта на вкладке «Счета» (§4.5): цветная карточка · имя и тип · баланс.
/// Номера карты в модели нет — в подписи только тип (§6).
struct AccountRow: View {
    let account: AccountModel
    let balance: Decimal

    var body: some View {
        HStack(spacing: Theme.Accounts.textGap) {
            AccountColorCard(
                colorHex: account.colorHex,
                width: Theme.Accounts.colorCardWidth,
                height: Theme.Accounts.colorCardHeight
            )
            VStack(alignment: .leading, spacing: Theme.Row.textSpacing) {
                Text(account.name)
                    .font(Theme.Font.rowTitle)
                    .foregroundStyle(Theme.Colors.ink)
                    .lineLimit(1)
                Text(account.accountType.title)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
            }
            Spacer(minLength: Theme.Spacing.s)
            Text(MoneyFormatter.balance(balance, currency: account.currency))
                .font(Theme.Font.rowAmount)
                .monospacedDigit()
                .foregroundStyle(balance < 0 ? Theme.Colors.negativeBalance : Theme.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(Theme.Size.summaryMinScale)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
        .contentShape(Rectangle())
    }
}
