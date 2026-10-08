import SwiftUI

struct AccountPillButton: View {
    let account: AccountModel
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                AppIcon.image(named: account.iconName).font(.caption)
                Text(account.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, Theme.Spacing.s)
            .background(
                isSelected ? (Color(hex: account.colorHex) ?? .blue) : Color(.systemGray5),
                in: Capsule()
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}
