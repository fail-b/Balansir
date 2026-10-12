import Testing
import Foundation
@testable import Balansir

/// Деньги по локали (задача 10). Пробелы нормализуются: ICU ставит неразрывные.
@Suite("MoneyFormatter")
@MainActor
struct MoneyFormatterTests {

    private func format(_ amount: Decimal, _ locale: Locale, currency: String = "RUB") -> String {
        MoneyFormatter.format(amount, currency: currency, locale: locale).normalizedSpaces
    }

    private func compact(_ amount: Decimal, _ locale: Locale) -> String {
        MoneyFormatter.compact(amount, locale: locale).normalizedSpaces
    }

    // MARK: - ru_RU

    @Test func ru_большая_сумма_без_копеек() {
        #expect(format(84320, TestLocale.ru) == "84 320 ₽")
    }

    @Test func ru_ровная_сумма_меньше_100_без_дробной_части() {
        #expect(format(50, TestLocale.ru) == "50 ₽")
    }

    @Test func ru_дробная_сумма_меньше_100_с_копейками() {
        #expect(format(Decimal(string: "49.99")!, TestLocale.ru) == "49,99 ₽")
    }

    @Test func ru_ровно_100_и_нуль() {
        #expect(format(100, TestLocale.ru) == "100 ₽")
        #expect(format(0, TestLocale.ru) == "0 ₽")
    }

    @Test func ru_отрицательная_сумма_форматируется_как_абсолютная() {
        #expect(format(-2400, TestLocale.ru) == "2 400 ₽")
    }

    @Test func ru_валюта_usd() {
        #expect(format(1000, TestLocale.ru, currency: "USD") == "1 000 $")
    }

    @Test func ru_compact_до_миллиона_как_обычный() {
        #expect(compact(999_999, TestLocale.ru) == "999 999 ₽")
    }

    @Test func ru_compact_миллионы_и_миллиарды() {
        #expect(compact(1_000_000, TestLocale.ru) == "1 млн ₽")
        #expect(compact(1_240_000, TestLocale.ru) == "1,2 млн ₽")
        #expect(compact(2_000_000_000, TestLocale.ru) == "2 млрд ₽")
    }

    @Test func ru_compact_отрицательные_с_минусом_U2212() {
        #expect(compact(-18_400, TestLocale.ru) == "\u{2212}18 400 ₽")
        #expect(compact(-1_500_000, TestLocale.ru) == "\u{2212}1,5 млн ₽")
    }

    @Test func ru_balance_со_знаком_только_для_отрицательных() {
        #expect(MoneyFormatter.balance(2400, locale: TestLocale.ru).normalizedSpaces == "2 400 ₽")
        #expect(MoneyFormatter.balance(-2400, locale: TestLocale.ru).normalizedSpaces == "\u{2212}2 400 ₽")
        #expect(MoneyFormatter.balance(0, locale: TestLocale.ru).normalizedSpaces == "0 ₽")
    }

    // MARK: - en_US

    @Test func en_символ_перед_суммой_запятая_для_тысяч() {
        #expect(format(84320, TestLocale.en) == "₽84,320")
        #expect(format(1000, TestLocale.en, currency: "USD") == "$1,000")
    }

    @Test func en_копейки_через_точку() {
        #expect(format(Decimal(string: "49.99")!, TestLocale.en) == "₽49.99")
    }

    @Test func en_compact() {
        #expect(compact(1_240_000, TestLocale.en) == "₽1.2M")
        #expect(compact(2_000_000_000, TestLocale.en) == "₽2B")
    }

    // MARK: - de_DE

    @Test func de_точка_для_тысяч_символ_после_суммы() {
        #expect(format(84320, TestLocale.de) == "84.320 ₽")
        #expect(format(1000, TestLocale.de, currency: "EUR") == "1.000 €")
    }

    @Test func de_копейки_через_запятую() {
        #expect(format(Decimal(string: "49.99")!, TestLocale.de) == "49,99 ₽")
    }

    @Test func de_compact() {
        #expect(compact(1_240_000, TestLocale.de) == "1,2 Mio. ₽")
    }
}
