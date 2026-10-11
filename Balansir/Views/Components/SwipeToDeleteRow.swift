import SwiftUI

/// Строка со свайпом влево для удаления (§4.2). Работает внутри `ScrollView`,
/// где нативный `.swipeActions` не действует (он только внутри `List`).
/// - короткий свайп открывает кнопку «Удалить», тап по ней удаляет;
/// - длинный свайп (за `Theme.Swipe.fullSwipeFraction` ширины строки) удаляет одним движением,
///   в том числе если начать его от уже открытой кнопки;
/// - тап по строке вызывает `onTap`; если кнопка открыта — тап её закрывает;
/// - открытой может быть только одна строка (`openRowId` общий для ленты): свайп или тап
///   по другой строке закрывает открытую; тап при этом редактирование не открывает.
struct SwipeToDeleteRow<Content: View>: View {
    let id: UUID
    /// Какая строка ленты сейчас сдвинута; nil — ни одна. Сброс в nil закрывает строку.
    @Binding var openRowId: UUID?
    @ViewBuilder let content: Content
    let onTap: () -> Void
    /// Удаление. Возвращает `false`, если не удалось (строка тогда возвращается на место).
    let onDelete: () async -> Bool

    @State private var offset: CGFloat = 0
    @State private var startOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var rowWidth: CGFloat = 0
    /// Палец за порогом длинного свайпа: отпустить — удалить.
    @State private var isPastThreshold = false
    @State private var isDeleting = false

    private var actionWidth: CGFloat { Theme.Swipe.actionWidth }

    /// Порог длинного свайпа; пока ширина не измерена — не меньше двух кнопок.
    private var fullSwipeDistance: CGFloat {
        max(rowWidth * Theme.Swipe.fullSwipeFraction, actionWidth * 2)
    }

    var body: some View {
        content
            .background(Theme.Colors.card)
            // Тап — до `.offset`: зона касания едет вместе со строкой и не накрывает кнопку «Удалить».
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isDeleting else { return }
                if offset != 0 {
                    close()
                } else if openRowId != nil {
                    // Открыта другая строка — только закрываем её (как в списках iOS).
                    openRowId = nil
                } else {
                    onTap()
                }
            }
            .offset(x: offset)
            // Подложка — фон строки: по размеру строки, а не «резиновая».
            // Иначе в поиске с одним результатом она растягивалась в свободное место (красные полосы).
            .background(alignment: .trailing) { deleteAction }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { rowWidth = $0 }
            // Пан — на всю строку вместе с открытой кнопкой: досвайп можно начать и с неё.
            // UIKit-пан не блокирует вертикальный скролл ленты (в отличие от DragGesture).
            .gesture(HorizontalPanGesture(onChanged: dragChanged, onEnded: dragEnded))
            .sensoryFeedback(trigger: isPastThreshold) { _, isPast in
                isPast ? .impact(weight: .medium) : nil
            }
            .onChange(of: openRowId) { _, newId in
                // Открыли другую строку или ленту прокрутили — закрываемся.
                guard newId != id, offset != 0, !isDragging, !isDeleting else { return }
                close()
            }
            .onDisappear {
                // Сбрасываем свайп, чтобы при возврате на вкладку строка была закрыта
                // (TabView держит экраны в памяти и local @State сохраняется).
                reset()
                if openRowId == id { openRowId = nil }
            }
    }

    /// Красная подложка с кнопкой. Пока строка закрыта — не видна совсем.
    private var deleteAction: some View {
        let revealed = max(-offset, 0)
        // Кнопка по центру открытой зоны; за порогом — прилипает к краю строки и едет за пальцем.
        let trailingInset = isPastThreshold
            ? max(revealed - actionWidth, 0)
            : max((revealed - actionWidth) / 2, 0)
        // Красное — только в открытой зоне справа: под самой строкой подложки нет,
        // иначе на стыке строк (дробная высота) просвечивала красная линия.
        return Theme.Colors.expense
            .frame(width: revealed)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .overlay(alignment: .trailing) {
                Button {
                    performDelete()
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        AppIcon.image(named: AppIcon.trash)
                            .font(Theme.Font.swipeActionIcon)
                        Text("Удалить")
                            .font(Theme.Font.time)
                    }
                    .foregroundStyle(Theme.Colors.onColor)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, trailingInset)
                .animation(.snappy, value: isPastThreshold)
            }
            .opacity(offset < 0 ? 1 : 0)
    }

    private func dragChanged(_ translationX: CGFloat) {
        guard !isDeleting else { return }
        if !isDragging {
            isDragging = true
            startOffset = offset
            openRowId = id
        }
        // Влево — без ограничения (длинный свайп), вправо — не дальше исходного положения.
        offset = min(startOffset + translationX, 0)
        let isPast = -offset >= fullSwipeDistance
        if isPast != isPastThreshold { isPastThreshold = isPast }
    }

    private func dragEnded() {
        guard isDragging else { return }
        isDragging = false
        if isPastThreshold {
            performDelete()
            return
        }
        let shouldOpen = -offset > actionWidth / 2
        withAnimation(.snappy) {
            offset = shouldOpen ? -actionWidth : 0
        }
        // Открытая строка «занимает» ленту (могли сбросить скроллом, пока палец двигался).
        if shouldOpen {
            openRowId = id
        } else if openRowId == id {
            openRowId = nil
        }
    }

    /// Строка уезжает влево, затем удаляется. Если удаление не прошло — строка возвращается.
    private func performDelete() {
        guard !isDeleting else { return }
        isDeleting = true
        isPastThreshold = true
        withAnimation(.easeOut(duration: Theme.Swipe.removeDuration)) {
            offset = -max(rowWidth, fullSwipeDistance)
        } completion: {
            Task {
                let deleted = await onDelete()
                // При успехе строка исчезает из ленты сама; сбрасывать её не нужно (мигнула бы).
                if !deleted {
                    withAnimation(.snappy) { reset() }
                }
            }
        }
    }

    private func close() {
        withAnimation(.snappy) { offset = 0 }
        if openRowId == id { openRowId = nil }
    }

    private func reset() {
        offset = 0
        isDragging = false
        isDeleting = false
        isPastThreshold = false
    }
}
