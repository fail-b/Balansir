import SwiftUI

enum Theme {
    enum Colors {
        // Семантические токены UI
        static let accent = Color("Colors/accent")
        static let background = Color("Colors/background")
        static let card = Color("Colors/card")
        static let ink = Color("Colors/ink")
        static let ink2 = Color("Colors/ink2")
        static let separator = Color("Colors/separator")
        static let fill = Color("Colors/fill")
        static let fill2 = Color("Colors/fill2")
        static let key = Color("Colors/key")
        static let selection = Color("Colors/selection")
        // Типы операций
        static let expense = Color("Colors/expense")
        static let income = Color("Colors/income")
        static let transfer = Color("Colors/transfer")
        // Служебные
        static let negativeBalance = Color("Colors/negativeBalance")
        static let fallback = Color("Colors/fallback")
        static let shadow = Color("Colors/shadow")
        /// Белый текст/иконка на цветной заливке (напр. кнопка «Удалить»)
        static let onColor = Color("Colors/onColor")
    }

    /// Мягкая тень плавающих стеклянных элементов (таб-бар).
    enum Shadow {
        static let color = Colors.shadow
        static let radius: CGFloat = 18
        static let y: CGFloat = 6
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
        // Старые (используются в существующих View)
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        // Новые из дизайна
        static let card: CGFloat = 22
        static let hero: CGFloat = 26
        static let sheet: CGFloat = 38
        static let accountSheet: CGFloat = 44
        static let search: CGFloat = 12
        static let balanceField: CGFloat = 14
        static let accountColorCard: CGFloat = 5
    }

    enum Font {
        static let screenTitle = SwiftUI.Font.system(size: 34, weight: .bold)
        static let heroAmount = SwiftUI.Font.system(size: 34, weight: .bold).monospacedDigit()
        static let amountInput = SwiftUI.Font.system(size: 60, weight: .bold).monospacedDigit()
        static let sheetTitle = SwiftUI.Font.system(size: 17, weight: .semibold)
        static let sectionTitle = SwiftUI.Font.system(size: 15, weight: .semibold)
        static let rowTitle = SwiftUI.Font.system(size: 16, weight: .medium)
        static let rowAmount = SwiftUI.Font.system(size: 16, weight: .semibold)
        static let caption = SwiftUI.Font.system(size: 13)
        static let time = SwiftUI.Font.system(size: 12)
        static let tabLabel = SwiftUI.Font.system(size: 10, weight: .semibold)

        // Трекинг применяется через .tracking() на Text-view
        enum Tracking {
            static let screenTitle: CGFloat = -0.8
            static let heroAmount: CGFloat = -1
            static let amountInput: CGFloat = -2
        }
    }

    enum Palette {
        static let hexColors: [String] = [
            "#4CAF50", "#FFDD00", "#EF3124",
            "#009FDF", "#3F51B5", "#9B59B6",
            "#FF8C42", "#1C1C1E", "#4A90D9",
            "#FF6B6B", "#4ECDC4", "#45B7D1",
            "#96CEB4", "#DDA0DD", "#F7DC6F",
            "#1ABC9C", "#E91E63", "#607D8B",
        ]
    }
}
