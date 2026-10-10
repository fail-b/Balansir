import SwiftUI

/// Строка со свайпом влево для удаления. Работает внутри `ScrollView`,
/// где нативный `.swipeActions` не действует (он только внутри `List`).
/// Тап по строке вызывает `onTap`; если кнопка «Удалить» открыта — тап её закрывает.
struct SwipeToDeleteRow<Content: View>: View {
    @ViewBuilder let content: Content
    let onTap: () -> Void
    let onDelete: () -> Void

    /// Ширина зоны действия «Удалить».
    private let actionWidth: CGFloat = 88

    @State private var offset: CGFloat = 0
    @State private var startOffset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteButton

            content
                .background(Theme.Colors.card)
                .offset(x: offset)
                .contentShape(Rectangle())
                .onTapGesture {
                    if offset != 0 {
                        close()
                    } else {
                        onTap()
                    }
                }
                // UIKit-пан: не блокирует вертикальный скролл ленты (в отличие от DragGesture).
                .gesture(HorizontalPanGesture(onChanged: dragChanged, onEnded: dragEnded))
        }
        .onDisappear {
            // Сбрасываем свайп, чтобы при возврате на вкладку строка была закрыта
            // (TabView держит экраны в памяти и local @State сохраняется).
            offset = 0
            isDragging = false
        }
    }

    private var deleteButton: some View {
        HStack {
            Spacer()
            Button(role: .destructive) {
                onDelete()
                close()
            } label: {
                VStack(spacing: Theme.Spacing.xs) {
                    AppIcon.image(named: AppIcon.trash)
                        .font(.system(size: 18))
                    Text("Удалить")
                        .font(Theme.Font.time)
                }
                .foregroundStyle(Theme.Colors.onColor)
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
            }
            .buttonStyle(.plain)
        }
        .background(Theme.Colors.expense)
    }

    private func dragChanged(_ translationX: CGFloat) {
        if !isDragging {
            isDragging = true
            startOffset = offset
        }
        let proposed = startOffset + translationX
        offset = min(max(proposed, -actionWidth), 0)
    }

    private func dragEnded() {
        guard isDragging else { return }
        isDragging = false
        let shouldOpen = offset < -actionWidth / 2
        withAnimation(.snappy) {
            offset = shouldOpen ? -actionWidth : 0
        }
    }

    private func close() {
        withAnimation(.snappy) { offset = 0 }
    }
}
