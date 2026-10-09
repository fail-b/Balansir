import SwiftUI

/// Цветная «карточка» счёта — цвет как у банковской карты (§4.5/§4.7).
/// Размер параметризуется: строка счёта в операции — компактная, пикер/список — крупнее.
struct AccountColorCard: View {
    let colorHex: String
    var width: CGFloat = 30
    var height: CGFloat = 20

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.accountColorCard)
            .fill(Color(hex: colorHex) ?? Theme.Colors.fallback)
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.accountColorCard)
                    .strokeBorder(Theme.Colors.ink.opacity(0.15), lineWidth: 0.5)
            }
    }
}
