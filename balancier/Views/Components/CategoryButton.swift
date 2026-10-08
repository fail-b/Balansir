import SwiftUI

struct CategoryButton: View {
    let category: CategoryModel
    let isSelected: Bool
    let action: () -> Void

    private var color: Color { Color(hex: category.colorHex) ?? Theme.Colors.fallback }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    AppIcon.image(named: category.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : color)
                }
                Text(category.name)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? color : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}
