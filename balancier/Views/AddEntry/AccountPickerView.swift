import SwiftUI

/// Какое поле счёта выбираем (§4.7, экран 11).
enum AccountPickerTarget: Hashable {
    case from
    case to
}

struct AccountPickerView: View {
    let title: String
    let accounts: [AccountModel]
    let selectedId: UUID?
    let balanceText: (AccountModel) -> String
    let onSelect: (AccountModel) -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        Button { onSelect(account) } label: {
                            row(for: account)
                        }
                        .buttonStyle(.plain)
                        if index < accounts.count - 1 {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.m)
            }
        }
        .background(Theme.Colors.background)
    }

    private var header: some View {
        ZStack {
            Text(title)
                .font(Theme.Font.sheetTitle)
                .foregroundStyle(Theme.Colors.ink)
            HStack {
                Button(action: onBack) {
                    AppIcon.image(named: AppIcon.back)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(width: 44, height: 44)
                        .glassEffect(in: .circle)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.m)
    }

    private func row(for account: AccountModel) -> some View {
        HStack(spacing: Theme.Spacing.m) {
            AccountColorCard(colorHex: account.colorHex, width: 40, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.Colors.ink)
                Text(balanceText(account))
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Colors.ink2)
            }
            Spacer()
            if account.id == selectedId {
                AppIcon.image(named: AppIcon.checkmark)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
        .contentShape(Rectangle())
    }
}
