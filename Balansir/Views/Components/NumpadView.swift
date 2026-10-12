import SwiftUI

/// Раскладка самописной цифровой клавиатуры.
enum NumpadLayout {
    /// Сумма операции (§4.7): 3 колонки, нижний ряд «, 0 ⌫».
    case amount
    /// Баланс счёта (§4.6): 4 колонки — справа ⌫ (на 3 ряда) и «−» внизу, «0» на 2 колонки.
    /// Здесь же позже появятся арифметические клавиши калькулятора.
    case signedAmount
}

/// Капсульная цифровая клавиатура. Логика ввода — в `AmountInput` (через VM), сюда — один колбэк.
struct NumpadView: View {
    /// Десятичный разделитель на клавише — из локали («,» в ru, «.» в en).
    @Environment(\.locale) private var locale
    var layout: NumpadLayout = .amount
    let onKey: (NumpadKey) -> Void

    private let spacing = Theme.Spacing.s
    private let keyHeight = Theme.Numpad.keyHeight

    var body: some View {
        switch layout {
        case .amount: amountLayout
        case .signedAmount: signedLayout
        }
    }

    private var amountLayout: some View {
        VStack(spacing: spacing) {
            digitRows
            HStack(spacing: spacing) {
                key(.separator)
                key(.digit(0))
                key(.backspace)
            }
        }
    }

    private var signedLayout: some View {
        // Ширина правой колонки = ширина одной клавиши из 4 в ряд.
        GeometryReader { geo in
            let keyWidth = (geo.size.width - spacing * 3) / 4
            HStack(alignment: .top, spacing: spacing) {
                Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                    ForEach(Self.digitRowValues, id: \.self) { row in
                        GridRow {
                            ForEach(row, id: \.self) { digit in key(.digit(digit)) }
                        }
                    }
                    GridRow {
                        key(.separator)
                        key(.digit(0)).gridCellColumns(2)
                    }
                }
                VStack(spacing: spacing) {
                    key(.backspace, height: keyHeight * 3 + spacing * 2)
                    key(.minus)
                }
                .frame(width: keyWidth)
            }
        }
        .frame(height: keyHeight * 4 + spacing * 3)
    }

    private static let digitRowValues = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

    private var digitRows: some View {
        ForEach(Self.digitRowValues, id: \.self) { row in
            HStack(spacing: spacing) {
                ForEach(row, id: \.self) { digit in key(.digit(digit)) }
            }
        }
    }

    private func key(_ key: NumpadKey, height: CGFloat? = nil) -> some View {
        Button { onKey(key) } label: {
            label(for: key)
                .foregroundStyle(Theme.Colors.ink)
                .frame(maxWidth: .infinity)
                .frame(height: height ?? keyHeight)
                .background(Theme.Colors.key, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: key))
    }

    @ViewBuilder
    private func label(for key: NumpadKey) -> some View {
        switch key {
        case .digit(let digit): Text(verbatim: "\(digit)").font(Theme.Font.numpadKey)
        case .separator: Text(verbatim: locale.decimalSeparator ?? ".").font(Theme.Font.numpadKey)
        case .minus: Text(verbatim: "\u{2212}").font(Theme.Font.numpadKey)
        case .backspace: AppIcon.image(named: AppIcon.backspace).font(Theme.Font.numpadIcon)
        }
    }

    private func accessibilityLabel(for key: NumpadKey) -> String {
        switch key {
        case .digit(let digit): "\(digit)"
        case .separator: String(localized: "Decimal separator")
        case .minus: String(localized: "Minus")
        case .backspace: String(localized: "Delete")
        }
    }
}
