import Testing
import Foundation
@testable import Balansir

@Suite("AmountInput")
@MainActor
struct AmountInputTests {

    private func input(_ keys: [NumpadKey], allowsNegative: Bool = false) -> AmountInput {
        var input = AmountInput(allowsNegative: allowsNegative)
        for key in keys { input.apply(key) }
        return input
    }

    // MARK: правила ввода (§4.7)

    @Test func цифра_заменяет_ведущий_ноль() {
        #expect(input([.digit(5)]).text == "5")
        #expect(input([.digit(0), .digit(0)]).text == "0")
    }

    @Test func не_больше_9_цифр_целой_части() {
        let keys = (1...9).map { NumpadKey.digit($0) } + [.digit(0)]
        #expect(input(keys).text == "123456789")
    }

    @Test func не_больше_2_знаков_после_запятой() {
        #expect(input([.digit(5), .separator, .digit(1), .digit(2), .digit(3)]).text == "5.12")
    }

    @Test func запятая_на_нуле_даёт_ноль_запятую_и_повтор_игнорируется() {
        let value = input([.separator, .separator])
        #expect(value.text == "0.")
        #expect(value.formatted(locale: TestLocale.ru).normalizedSpaces == "0,")
        #expect(value.value == 0)
    }

    @Test func незаконченная_дробь_сохраняется_как_целое() {
        #expect(input([.digit(1), .digit(2), .separator]).value == 12)
    }

    @Test func backspace_удаляет_символ_и_не_уходит_ниже_нуля() {
        var value = input([.digit(1), .digit(2)])
        value.apply(.backspace)
        #expect(value.text == "1")
        value.apply(.backspace)
        #expect(value.text == "0")
        value.apply(.backspace)
        #expect(value.text == "0")
        #expect(value.isEmpty)
    }

    @Test func formatted_группирует_тысячи_пробелами() {
        let keys = (1...7).map { NumpadKey.digit($0) }
        #expect(input(keys).formatted(locale: TestLocale.ru).normalizedSpaces == "1 234 567")
    }

    // MARK: минус (баланс счёта, §4.6)

    @Test func минус_без_allowsNegative_игнорируется() {
        let value = input([.minus, .digit(5)])
        #expect(value.text == "5")
        #expect(value.value == 5)
    }

    @Test func минус_в_начале_делает_число_отрицательным() {
        let value = input([.minus, .digit(1), .digit(2), .digit(3), .digit(4), .separator, .digit(5), .digit(6)], allowsNegative: true)
        #expect(value.value == Decimal(string: "-1234.56"))
        #expect(value.formatted(locale: TestLocale.ru).normalizedSpaces == "\u{2212}1 234,56")
    }

    @Test func минус_после_цифры_или_запятой_игнорируется() {
        #expect(input([.digit(5), .minus], allowsNegative: true).value == 5)
        #expect(input([.separator, .minus], allowsNegative: true).text == "0.")
    }

    @Test func повторный_минус_игнорируется() {
        #expect(input([.minus, .minus, .digit(7)], allowsNegative: true).text == "-7")
    }

    @Test func минус_ноль_показывается_но_сохраняется_как_ноль() {
        let value = input([.minus], allowsNegative: true)
        #expect(value.formatted(locale: TestLocale.ru).normalizedSpaces == "\u{2212}0")
        #expect(value.value == 0)
        #expect(value.isEmpty == false)
    }

    @Test func backspace_на_минус_ноле_снимает_знак() {
        var value = input([.minus, .digit(5)], allowsNegative: true)
        value.apply(.backspace)
        #expect(value.text == "-0")
        value.apply(.backspace)
        #expect(value.text == "0")
        #expect(value.isEmpty)
    }

    @Test func знак_не_входит_в_лимит_цифр() {
        let keys: [NumpadKey] = [.minus] + (1...9).map { NumpadKey.digit($0) }
        #expect(input(keys, allowsNegative: true).text == "-123456789")
    }

    // MARK: начальное значение (редактирование)

    @Test func init_decimal_положительное() {
        let value = AmountInput(decimal: Decimal(string: "1234.5")!)
        #expect(value.text == "1234.5")
        #expect(value.formatted(locale: TestLocale.ru).normalizedSpaces == "1 234,5")
    }

    @Test func init_decimal_отрицательное_с_минусом() {
        let value = AmountInput(decimal: Decimal(string: "-1500.25")!, allowsNegative: true)
        #expect(value.text == "-1500.25")
        #expect(value.value == Decimal(string: "-1500.25"))
    }

    @Test func init_decimal_отрицательное_без_минуса_берёт_модуль() {
        #expect(AmountInput(decimal: -300).text == "300")
    }

    @Test func init_decimal_округляет_до_копеек_и_ноль_без_знака() {
        #expect(AmountInput(decimal: Decimal(string: "10.555")!).text == "10.56")
        #expect(AmountInput(decimal: Decimal(string: "-0.001")!, allowsNegative: true).text == "0")
    }

    @Test func продолжение_ввода_после_init_decimal() {
        var value = AmountInput(decimal: 12)
        value.apply(.digit(3))
        #expect(value.text == "123")
    }

    // MARK: разделители по локали (задача 10)

    @Test func formatted_en_US_запятая_для_тысяч_точка_для_дроби() {
        let value = input([.digit(1), .digit(2), .digit(3), .digit(4), .separator, .digit(5)])
        #expect(value.formatted(locale: TestLocale.en) == "1,234.5")
    }

    @Test func formatted_de_DE_точка_для_тысяч_запятая_для_дроби() {
        let value = input([.digit(1), .digit(2), .digit(3), .digit(4), .separator, .digit(5)])
        #expect(value.formatted(locale: TestLocale.de) == "1.234,5")
    }
}
