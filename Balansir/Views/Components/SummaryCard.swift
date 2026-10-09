import SwiftUI

struct SummaryCard: View {
    let title: String
    let amount: Decimal
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Image(systemName: icon).foregroundStyle(color)
                Text(title).font(.subheadline).foregroundStyle(.secondary)
            }
            Text((amount as NSDecimalNumber).doubleValue, format: .currency(code: "RUB"))
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.l)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.l))
    }
}
