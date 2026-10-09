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
}
