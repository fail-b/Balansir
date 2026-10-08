import SwiftUI

struct AccountSettingsRow: View {
    let account: AccountModel
    let balance: Decimal

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.Radius.s)
                    .fill(Color(hex: account.colorHex) ?? Theme.Colors.fallback)
                    .frame(width: 36, height: 36)
                AppIcon.image(named: account.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name).font(.callout).fontWeight(.medium)
                Text(account.accountType.title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text((balance as NSDecimalNumber).doubleValue, format: .currency(code: account.currency))
                .font(.callout).fontWeight(.semibold)
                .foregroundStyle(balance >= 0 ? Color.primary : Theme.Colors.negativeBalance)
        }
    }
}
