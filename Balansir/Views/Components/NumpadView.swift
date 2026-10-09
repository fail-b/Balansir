import SwiftUI

/// Капсульная цифровая клавиатура (§4.7). Логика ввода — в AddEntryViewModel,
/// сюда передаются колбэки.
struct NumpadView: View {
    let onDigit: (String) -> Void
    let onSeparator: () -> Void
    let onBackspace: () -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [",", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(row, id: \.self) { key in
                        Button { handleKey(key) } label: {
                            Group {
                                if key == "⌫" {
                                    AppIcon.image(named: AppIcon.backspace)
                                        .font(.system(size: 22))
                                } else {
                                    Text(key).font(.system(size: 26, weight: .medium))
                                }
                            }
                            .foregroundStyle(Theme.Colors.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.Colors.key, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫": onBackspace()
        case ",": onSeparator()
        default: onDigit(key)
        }
    }
}
