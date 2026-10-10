import SwiftUI

extension View {
    /// Сообщает в `isScrolled`, прокручен ли скролл-контейнер ниже порога.
    /// Нужно, чтобы показывать мини-бар (сводку в таб-баре) только при скролле,
    /// а у верха списка — скрывать его.
    func reportsScroll(threshold: CGFloat = 30, to isScrolled: Binding<Bool>) -> some View {
        onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > threshold
        } action: { _, newValue in
            if isScrolled.wrappedValue != newValue {
                isScrolled.wrappedValue = newValue
            }
        }
    }

    /// Сообщает в `overscroll`, на сколько pt список оттянут вниз за верхний край (0, если не оттянут).
    /// Жест «потянуть вниз» → поиск на Главной (§4.1.4) строится только на этом, без DragGesture.
    func reportsOverscroll(to overscroll: Binding<CGFloat>) -> some View {
        onScrollGeometryChange(for: CGFloat.self) { geometry in
            max(0, -(geometry.contentOffset.y + geometry.contentInsets.top))
        } action: { _, newValue in
            if overscroll.wrappedValue != newValue {
                overscroll.wrappedValue = newValue
            }
        }
    }

    /// Сообщает в `scrollable`, длиннее ли контент видимой области.
    /// Нужно, чтобы свайп вверх закрывал поиск только когда список не прокручивается (§4.1.4).
    func reportsScrollable(to scrollable: Binding<Bool>) -> some View {
        onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentSize.height > geometry.containerSize.height
        } action: { _, newValue in
            if scrollable.wrappedValue != newValue {
                scrollable.wrappedValue = newValue
            }
        }
    }

    /// Запас снизу под мини-бар, чтобы последняя строка списка не пряталась под ним
    /// при свёрнутом таб-баре. Ставить на ScrollView/List каждой вкладки.
    func clearsBottomAccessory() -> some View {
        contentMargins(.bottom, Theme.Size.bottomAccessoryClearance, for: .scrollContent)
    }
}
