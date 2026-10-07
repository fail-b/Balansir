import SwiftUI

extension Color {
    init?(hex: String) {
        var hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex = String(hex.dropFirst()) }
        guard hex.count == 6 else { return nil }
        var rgb: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    func toHexString() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// Predefined palette for accounts and categories
extension Color {
    static let palette: [Color] = [
        Color(hex: "#4A90D9")!, Color(hex: "#FFDD00")!, Color(hex: "#EF3124")!,
        Color(hex: "#4CAF50")!, Color(hex: "#009FDF")!, Color(hex: "#9B59B6")!,
        Color(hex: "#FF6B6B")!, Color(hex: "#FF8C42")!, Color(hex: "#4ECDC4")!,
        Color(hex: "#45B7D1")!, Color(hex: "#96CEB4")!, Color(hex: "#DDA0DD")!,
        Color(hex: "#F7DC6F")!, Color(hex: "#1ABC9C")!, Color(hex: "#E91E63")!,
        Color(hex: "#00BCD4")!, Color(hex: "#FF5722")!, Color(hex: "#607D8B")!,
    ]

    static let paletteHex: [String] = [
        "#4A90D9", "#FFDD00", "#EF3124",
        "#4CAF50", "#009FDF", "#9B59B6",
        "#FF6B6B", "#FF8C42", "#4ECDC4",
        "#45B7D1", "#96CEB4", "#DDA0DD",
        "#F7DC6F", "#1ABC9C", "#E91E63",
        "#00BCD4", "#FF5722", "#607D8B",
    ]
}
