import Foundation

enum MoneyFormatter {
    private static let fullFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "ru_RU")
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f
    }()

    private static let centFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "ru_RU")
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()

    // Для компактного формата (1,2 млн): до 1 знака после запятой, запятая ru_RU, «,0» отбрасывается.
    private static let compactFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "ru_RU")
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()

    private static let symbols: [String: String] = ["RUB": "₽", "USD": "$", "EUR": "€"]

    /// Символ валюты по ISO-коду (зависит от валюты счёта, не константа).
    static func symbol(for currency: String) -> String {
        symbols[currency] ?? currency
    }

    // Форматирует абсолютное значение суммы. Знак (−/+) добавляет вызывающий код.
    static func format(_ amount: Decimal, currency: String = "RUB") -> String {
        let absAmount = abs(amount)
        let formatter = absAmount < 100 ? centFormatter : fullFormatter
        let formatted = formatter.string(from: absAmount as NSDecimalNumber) ?? "\(absAmount)"
        return "\(formatted) \(symbol(for: currency))"
    }

    /// Компактный формат для карусели счетов (§1): до 999 999 — как `format`;
    /// от 1 млн — «1,2 млн ₽»; от 1 млрд — «1,5 млрд ₽». Знак минуса — U+2212.
    static func compact(_ amount: Decimal, currency: String = "RUB") -> String {
        let sign = amount < 0 ? "\u{2212}" : ""
        let absAmount = abs(amount)
        if absAmount >= 1_000_000_000 {
            return sign + scaled(absAmount, divisor: 1_000_000_000, suffix: "млрд", currency: currency)
        } else if absAmount >= 1_000_000 {
            return sign + scaled(absAmount, divisor: 1_000_000, suffix: "млн", currency: currency)
        } else {
            return sign + format(absAmount, currency: currency)
        }
    }

    private static func scaled(_ amount: Decimal, divisor: Decimal, suffix: String, currency: String) -> String {
        let value = amount / divisor
        let number = compactFormatter.string(from: value as NSDecimalNumber) ?? "\(value)"
        return "\(number) \(suffix) \(symbol(for: currency))"
    }
}
