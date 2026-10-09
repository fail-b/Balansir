import SwiftUI

enum CategoryIconStyle: String {
    case dot, mono, color
}

struct CategoryIcon: View {
    let category: CategoryModel
    var style: CategoryIconStyle = .dot
    var size: CGFloat = 40

    private var iconSize: CGFloat { size * 0.45 }
    private var categoryColor: Color { Color(hex: category.colorHex) ?? Theme.Colors.fallback }

    var body: some View {
        Circle()
            .fill(backgroundFill)
            .frame(width: size, height: size)
            .overlay {
                AppIcon.image(named: resolvedIconName)
                    .font(.system(size: iconSize))
                    .foregroundStyle(iconColor)
            }
            .overlay(alignment: .bottomTrailing) {
                if style == .dot {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 12, height: 12)
                        .overlay { Circle().strokeBorder(Theme.Colors.card, lineWidth: 2) }
                        .offset(x: 2, y: 2)
                }
            }
    }

    private var backgroundFill: Color {
        style == .color ? categoryColor.opacity(0.15) : Theme.Colors.fill
    }

    private var iconColor: Color {
        style == .color ? categoryColor : Theme.Colors.ink
    }

    // Для стиля «Цвет» пробует .fill-вариант SF Symbol
    private var resolvedIconName: String {
        guard style == .color else { return category.iconName }
        let fillName = category.iconName + ".fill"
        if UIImage(systemName: fillName) != nil { return fillName }
        return category.iconName
    }
}
