import SwiftUI

struct NumpadView: View {
    @Binding var amountString: String

    private let rows: [[String]] = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        [".", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { key in
                        Button { handleKey(key) } label: {
                            Group {
                                if key == "⌫" {
                                    Image(systemName: "delete.left").font(.title3)
                                } else {
                                    Text(key).font(.title2).fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: Theme.Radius.s))
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫":
            amountString = amountString.count > 1 ? String(amountString.dropLast()) : "0"
        case ".":
            if !amountString.contains(".") { amountString += "." }
        default:
            if amountString == "0" { amountString = key }
            else if amountString.count < 12 { amountString += key }
        }
    }
}
