import SwiftUI

struct CategoryStatRow: View {
    let category: CategoryModel
    let amount: Decimal
    let total: Decimal

    private var color: Color { Color(hex: category.colorHex) ?? .orange }
    private var percentage: Double {
        total > 0 ? NSDecimalNumber(decimal: amount / total).doubleValue : 0
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    AppIcon.image(named: category.iconName)
                        .font(.system(size: 15))
                        .foregroundStyle(color)
                }
                Text(category.name).font(.callout)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text((amount as NSDecimalNumber).doubleValue, format: .currency(code: "RUB"))
                        .font(.callout).fontWeight(.semibold)
                    Text("\(Int(percentage * 100))%")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray5)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * percentage, height: 4)
                }
            }
            .frame(height: 4)
            .padding(.leading, 48)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, 10)
    }
}
