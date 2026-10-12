import SwiftUI

/// Чип тега `#Тег` в строке операции (§4.2). С `action` — кнопка (поиск по тегу), без — просто подпись.
struct TagChip: View {
    let name: String
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) { label }
                .buttonStyle(.plain)
        } else {
            label
        }
    }

    private var label: some View {
        Text(verbatim: "#\(name)")
            .font(Theme.Font.tagChip)
            .foregroundStyle(Theme.Colors.ink2)
            .lineLimit(1)
            .padding(.horizontal, Theme.TagSize.rowHorizontalPadding)
            .padding(.vertical, Theme.TagSize.rowVerticalPadding)
            .background(Theme.Colors.fill, in: Capsule())
    }
}
