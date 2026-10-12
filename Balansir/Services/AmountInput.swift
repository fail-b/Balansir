import Foundation

/// Клавиша самописной цифровой клавиатуры (`NumpadView`).
/// Задел под калькулятор в шите операции: позже добавятся `.plus`, `.multiply`, `.divide`, `.equals`.
enum NumpadKey: Hashable {
    case digit(Int)
    case separator
    case backspace
    /// Знак «−» перед числом (только в начале ввода, только если `allowsNegative`).
    case minus
}

/// Ввод суммы с цифровой клавиатуры — общая логика без UI для шита операции (§4.7)
/// и поля «Баланс» в шите счёта (§4.6).
/// Модуль хранится строкой с разделителем «.» (для `Decimal`), «,» — только на экране.
struct AmountInput {
    static let maxIntegerDigits = 9
    static let maxFractionDigits = 2

    /// Разрешён ли «−» (баланс счёта — да, сумма операции — нет).
    let allowsNegative: Bool
    private(set) var isNegative = false
    /// Модуль без знака: «0», «12», «12.», «12.5».
    private(set) var magnitude = "0"

    init(allowsNegative: Bool = false) {
        self.allowsNegative = allowsNegative
    }

    /// Начальное значение (редактирование). Округляется до 2 знаков; без `allowsNegative` берётся модуль.
    init(decimal: Decimal, allowsNegative: Bool = false) {
        self.allowsNegative = allowsNegative
        var source = decimal
        var rounded = Decimal()
        NSDecimalRound(&rounded, &source, Self.maxFractionDigits, .plain)
        let negative = rounded < 0
        let absolute = negative ? -rounded : rounded
        // stringValue не зависит от локали: всегда «.» и без группировки.
        magnitude = NSDecimalNumber(decimal: absolute).stringValue
        isNegative = negative && allowsNegative && absolute != 0
    }

    /// Строка вида «-1234.5» — для тестов и простых присваиваний.
    var text: String {
        get { (isNegative ? "-" : "") + magnitude }
        set {
            if newValue.hasPrefix("-") {
                isNegative = allowsNegative
                magnitude = String(newValue.dropFirst())
            } else {
                isNegative = false
                magnitude = newValue
            }
            if magnitude.isEmpty { magnitude = "0" }
        }
    }

    /// Значение суммы. «−0» и «−0,» дают 0 — у нуля знака нет.
    var value: Decimal {
        let absolute = Decimal(string: magnitude) ?? 0
        guard absolute != 0 else { return 0 }
        return isNegative ? -absolute : absolute
    }

    /// Ничего не введено (показывается серым «0»).
    var isEmpty: Bool { magnitude == "0" && !isNegative }

    /// Для показа: «−1 234 567,5». Целая часть группируется пробелами (локализация — задача 10).
    var formatted: String {
        let parts = magnitude.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        var result = (isNegative ? "\u{2212}" : "") + Self.groupThousands(String(parts[0]))
        if magnitude.contains(".") {
            result += "," + (parts.count > 1 ? String(parts[1]) : "")
        }
        return result
    }

    mutating func apply(_ key: NumpadKey) {
        switch key {
        case .digit(let digit):
            guard (0...9).contains(digit) else { return }
            if let dotIndex = magnitude.firstIndex(of: ".") {
                let fraction = magnitude[magnitude.index(after: dotIndex)...]
                if fraction.count >= Self.maxFractionDigits { return }
                magnitude += "\(digit)"
            } else if magnitude == "0" {
                magnitude = "\(digit)"              // цифра при «0» заменяет его
            } else {
                if magnitude.count >= Self.maxIntegerDigits { return }
                magnitude += "\(digit)"
            }
        case .separator:
            if !magnitude.contains(".") { magnitude += "." }   // «,» на нуле → «0,»
        case .backspace:
            if magnitude.count > 1 {
                magnitude.removeLast()
            } else if magnitude != "0" {
                magnitude = "0"
            } else {
                isNegative = false                  // «−0» → «0»: стираем знак
            }
        case .minus:
            // Только в начале ввода: до первой цифры и запятой.
            guard allowsNegative, magnitude == "0" else { return }
            isNegative = true
        }
    }

    private static let groupingFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f
    }()

    private static func groupThousands(_ digits: String) -> String {
        guard let number = Int(digits) else { return digits }
        return groupingFormatter.string(from: NSNumber(value: number)) ?? digits
    }
}
