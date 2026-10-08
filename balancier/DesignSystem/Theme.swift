import SwiftUI

enum Theme {
    // Семантические цвета — заменить на Color("...") после добавления Color Set в Assets
    enum Colors {
        static let expense = Color.red
        static let income = Color.green
        static let transfer = Color.blue
        static let negativeBalance = Color.red
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 28
    }

    enum Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
    }

    enum Palette {
        static let hexColors: [String] = [
            "#4A90D9", "#FFDD00", "#EF3124",
            "#4CAF50", "#009FDF", "#9B59B6",
            "#FF6B6B", "#FF8C42", "#4ECDC4",
            "#45B7D1", "#96CEB4", "#DDA0DD",
            "#F7DC6F", "#1ABC9C", "#E91E63",
            "#00BCD4", "#FF5722", "#607D8B",
        ]
    }
}
