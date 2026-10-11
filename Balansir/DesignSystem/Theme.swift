import SwiftUI

enum Theme {
    enum Colors {
        // Семантические токены UI
        static let accent = Color("Colors/accent")
        static let background = Color("Colors/background")
        static let card = Color("Colors/card")
        static let ink = Color("Colors/ink")
        static let ink2 = Color("Colors/ink2")
        /// Третичный текст: заметка «#…» в строке операции (§4.2). Светлее `ink2`.
        static let ink3 = Color("Colors/ink3")
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

    /// Размеры управляющих элементов.
    enum Size {
        /// Высота строки поиска и круглых стеклянных кнопок в шапке (44 pt, §4.1.4).
        static let searchBar: CGFloat = 44
        /// Запас под мини-бар (`tabViewBottomAccessory`) внизу скроллов вкладок.
        /// Когда таб-бар свёрнут и мини-бар встаёт в одну строку с ним, система не учитывает
        /// мини-бар в нижнем отступе — без запаса последняя строка уходит под него.
        static let bottomAccessoryClearance: CGFloat = 56
        /// Толщина разделителя строк в карточках-списках.
        static let hairline: CGFloat = 0.5
        /// Минимальный масштаб сумм в сводке у таб-бара — длинная сумма ужимается, а не обрезается.
        static let summaryMinScale: CGFloat = 0.7
    }

    /// Строка операции `EntryRow` (§4.2).
    enum Row {
        /// Иконка категории/перевода.
        static let iconSize: CGFloat = 40
        /// Вертикальный паддинг строки.
        static let verticalPadding: CGFloat = 10
        /// Зазор между названием и подписью, суммой и временем.
        static let textSpacing: CGFloat = 2
        /// Отступ разделителя слева: паддинг 16 + иконка 40 + зазор 12.
        static let separatorInset: CGFloat = 68
    }

    /// Свайп влево по строке операции → удаление (§4.2).
    enum Swipe {
        /// Ширина открытой кнопки «Удалить».
        static let actionWidth: CGFloat = 88
        /// Длинный свайп: доля ширины строки, за которой отпускание удаляет операцию.
        static let fullSwipeFraction: CGFloat = 0.5
        /// Строка уезжает влево перед удалением, с.
        static let removeDuration: Double = 0.2
        /// Сколько висит плашка «Удалено · Отменить», с.
        static let undoDuration: Double = 4
    }

    /// Экран «Статистика» (§4.4).
    enum Stats {
        /// Высота области столбиков по дням.
        static let chartHeight: CGFloat = 110
        /// Зазор между столбиками.
        static let barGap: CGFloat = 3
        static let barRadius: CGFloat = 2
        /// Минимальная высота столбика (и высота столбиков будущих дней).
        static let barMinHeight: CGFloat = 4
        /// Цветная точка категории в списке.
        static let categoryDot: CGFloat = 10
        /// Высота полоски прогресса категории.
        static let progressHeight: CGFloat = 4
        /// Ширина колонки суммы (выравнивание вправо).
        static let amountColumnWidth: CGFloat = 92
        /// Отступ разделителя строк слева (под текст, после точки).
        static let separatorInset: CGFloat = 36
    }

    /// Жест «потянуть вниз» → поиск на Главной (§4.1.4).
    enum Pull {
        /// Оттяжка ленты вниз, при которой прогресс жеста достигает 1 (порог активации).
        static let threshold: CGFloat = 70
        /// «Подпрыгивание» лупы на пороге — сигнал «отпусти, будет поиск».
        static let magnifierScaleActive: CGFloat = 1.1
    }

    /// Анимации, общие для нескольких экранов.
    enum Animation {
        /// Морфинг лупы в строку поиска на Главной (§4.1.4): spring ~0.35 с, damping 0.8.
        static let searchMorph: SwiftUI.Animation = .spring(response: 0.35, dampingFraction: 0.8)
        /// Смена своей цифровой клавиатуры на системную в шите операции (§4.7).
        static let numpadToggle: SwiftUI.Animation = .easeInOut(duration: 0.25)
    }

    enum Spacing {
        /// Зазор между подписью и суммой в сводке у таб-бара.
        static let xxs: CGFloat = 1
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
        static let accountChip: CGFloat = 16
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
        /// Бренд-бук: Headline 17 semibold.
        static let headline = SwiftUI.Font.system(size: 17, weight: .semibold)
        /// Бренд-бук: Body 17.
        static let body = SwiftUI.Font.system(size: 17)
        /// Сумма в строке списка (Body semibold, табличные цифры).
        static let bodyAmount = SwiftUI.Font.system(size: 17, weight: .semibold).monospacedDigit()
        static let sectionTitle = SwiftUI.Font.system(size: 15, weight: .semibold)
        static let rowTitle = SwiftUI.Font.system(size: 16, weight: .medium)
        static let rowAmount = SwiftUI.Font.system(size: 16, weight: .semibold)
        /// Заметка «#…» в строке операции — в одной строке с названием, но не жирная.
        static let rowNote = SwiftUI.Font.system(size: 16)
        static let caption = SwiftUI.Font.system(size: 13)
        static let time = SwiftUI.Font.system(size: 12)
        /// Иконка перевода в строке операции и корзина в свайпе.
        static let rowIcon = SwiftUI.Font.system(size: 18)
        static let swipeActionIcon = SwiftUI.Font.system(size: 18)
        /// Плашка «Удалено · Отменить».
        static let toast = SwiftUI.Font.system(size: 15, weight: .medium)
        static let toastAction = SwiftUI.Font.system(size: 15, weight: .semibold)
        /// Подпись версии внизу Настроек (§4.8).
        static let appVersion = SwiftUI.Font.system(size: 12)
        static let searchField = SwiftUI.Font.system(size: 17)
        static let tabLabel = SwiftUI.Font.system(size: 10, weight: .semibold)
        /// Сводка у таб-бара (§3): подпись над суммой, основная сумма слева, вторая справа.
        static let summaryLabel = SwiftUI.Font.system(size: 13)
        static let summaryValue = SwiftUI.Font.system(size: 20, weight: .bold).monospacedDigit()
        static let summarySecondary = SwiftUI.Font.system(size: 17, weight: .medium).monospacedDigit()

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
