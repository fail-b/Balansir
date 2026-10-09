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
}
