import Foundation

/// Явные локали для тестов форматирования (задача 10): тесты не зависят от языка симулятора.
enum TestLocale {
    static let ru = Locale(identifier: "ru_RU")
    static let en = Locale(identifier: "en_US")
    static let de = Locale(identifier: "de_DE")
}

extension String {
    /// Неразрывные пробелы (U+00A0, U+202F), которые ставит ICU, → обычный пробел.
    /// Так ожидаемые строки в тестах читаются глазами и не ломаются от смены пробела в новой iOS.
    var normalizedSpaces: String {
        replacingOccurrences(of: "\u{00A0}", with: " ").replacingOccurrences(of: "\u{202F}", with: " ")
    }
}
