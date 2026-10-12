import SwiftUI

/// Плашка «Операция удалена · Отменить» внизу Главной (§4.2).
/// Время показа — `Theme.Swipe.undoDuration`, таймер — у экрана, который её показывает.
struct UndoToast: View {
    let title: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Text(title)
                .font(Theme.Font.toast)
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(1)
            Spacer(minLength: 0)
            Button("Undo", action: onUndo)
                .font(Theme.Font.toastAction)
                .foregroundStyle(Theme.Colors.accent)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .frame(height: Theme.Size.searchBar)
        .glassEffect(.regular, in: Capsule())
    }
}
