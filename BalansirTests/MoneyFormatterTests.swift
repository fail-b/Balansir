import Testing
import Foundation
@testable import Balansir

@Suite("MoneyFormatter")
@MainActor
struct MoneyFormatterTests {

    @Test func большая_сумма_без_копеек() {
        #expect(MoneyFormatter.format(84320) == "84\u{00A0}320 ₽")
    }

    @Test func тысячи_без_копеек() {
        #expect(MoneyFormatter.format(2400) == "2\u{00A0}400 ₽")
    }

    @Test func ровная_сумма_меньше_100_без_дробной_части() {
        #expect(MoneyFormatter.format(50) == "50 ₽")
    }

    @Test func дробная_сумма_меньше_100_с_копейками() {
        let amount = Decimal(string: "49.99")!
        #expect(MoneyFormatter.format(amount) == "49,99 ₽")
    }

    @Test func ровно_100_без_копеек() {
        #expect(MoneyFormatter.format(100) == "100 ₽")
    }

    @Test func нуль() {
        #expect(MoneyFormatter.format(0) == "0 ₽")
    }

    @Test func отрицательная_сумма_форматируется_как_абсолютная() {
        #expect(MoneyFormatter.format(-2400) == "2\u{00A0}400 ₽")
    }

    @Test func валюта_usd() {
        #expect(MoneyFormatter.format(1000, currency: "USD") == "1\u{00A0}000 $")
    }

    // MARK: - compact

    @Test func compact_до_миллиона_как_обычный() {
        #expect(MoneyFormatter.compact(999_999) == "999\u{00A0}999 ₽")
    }

    @Test func compact_ровно_миллион_без_дроби() {
        #expect(MoneyFormatter.compact(1_000_000) == "1 млн ₽")
    }

    @Test func compact_миллион_с_одним_знаком() {
        #expect(MoneyFormatter.compact(1_240_000) == "1,2 млн ₽")
    }

    @Test func compact_ровные_миллиарды_без_дроби() {
        #expect(MoneyFormatter.compact(2_000_000_000) == "2 млрд ₽")
    }

    @Test func compact_отрицательная_сумма_с_минусом_U2212() {
        #expect(MoneyFormatter.compact(-18_400) == "\u{2212}18\u{00A0}400 ₽")
    }

    @Test func compact_отрицательный_миллион() {
        #expect(MoneyFormatter.compact(-1_500_000) == "\u{2212}1,5 млн ₽")
    }
}
