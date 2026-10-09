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
}
