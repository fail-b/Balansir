import SwiftUI

enum AppIcon {
    static let accountPicker: [String] = [
        "creditcard", "banknote", "building.columns", "wallet.pass",
        "dollarsign.circle", "eurosign.circle", "sterlingsign.circle",
        "briefcase", "house", "car", "airplane", "cart",
    ]

    static let categoryPicker: [String] = [
        "fork.knife", "cart", "tram", "airplane", "car",
        "wrench.and.screwdriver", "tshirt", "creditcard",
        "star", "gamecontroller", "heart.text.square", "pills",
        "gift", "house", "briefcase", "iphone", "phone",
        "figure.run", "building.2",
        "dollarsign.circle", "laptopcomputer", "percent",
        "arrow.uturn.left", "ellipsis.circle",
    ]

    // Рендерит иконку: в будущем сначала проверяет кастомный ассет, затем SF Symbol
    static func image(named name: String) -> Image {
        if UIImage(named: name) != nil {
            return Image(name)
        }
        return Image(systemName: name)
    }
}
