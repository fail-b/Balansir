import SwiftUI

struct EntryRow: View {
    let entry: EntryModel
    var isLast: Bool = false

    @AppStorage("categoryIconStyle") private var iconStyle: CategoryIconStyle = .dot

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                iconView
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.displayTitle)
                        .font(Theme.Font.rowTitle)
                        .foregroundStyle(Theme.Colors.ink)
                    Text(subtitle)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Colors.ink2)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(amountString)
                        .font(Theme.Font.rowAmount)
                        .foregroundStyle(amountColor)
                    Text(entry.date, style: .time)
                        .font(Theme.Font.time)
                        .foregroundStyle(Theme.Colors.ink2)
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, 10)

            if !isLast {
                Rectangle()
                    .fill(Theme.Colors.separator)
                    .frame(height: 0.5)
                    .padding(.leading, 68)
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if entry.type == .transfer {
            Circle()
                .fill(Theme.Colors.fill)
                .overlay {
                    AppIcon.image(named: AppIcon.transfer)
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.Colors.transfer)
                }
        } else if let category = entry.category {
            CategoryIcon(category: category, style: iconStyle, size: 40)
        } else {
            Circle()
                .fill(Theme.Colors.fill)
        }
    }

    private var subtitle: String {
        let account = entry.displayAccount
        if let note = entry.note, !note.isEmpty {
            return "\(account) · \(note)"
        }
        return account
    }

    private var amountString: String {
        let formatted = MoneyFormatter.format(entry.amount, currency: entry.currency)
        switch entry.type {
        case .expense: return "\u{2212}\(formatted)"
        case .income: return "+\(formatted)"
        case .transfer: return formatted
        }
    }

    private var amountColor: Color {
        switch entry.type {
        case .expense: return Theme.Colors.ink
        case .income: return Theme.Colors.income
        case .transfer: return Theme.Colors.ink
        }
    }
}
