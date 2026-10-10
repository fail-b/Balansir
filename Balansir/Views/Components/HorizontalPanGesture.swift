import SwiftUI
import UIKit

/// Горизонтальный пан на UIKit для строк внутри `ScrollView`.
/// Начинается, только если движение преимущественно горизонтальное, — вертикальный
/// скролл не трогает. SwiftUI-`DragGesture` в `ScrollView` на iOS 18+ перехватывает скролл
/// (лента переставала прокручиваться вверх/вниз), поэтому здесь `UIPanGestureRecognizer`.
struct HorizontalPanGesture: UIGestureRecognizerRepresentable {
    /// Смещение пальца по X от начала жеста.
    var onChanged: (CGFloat) -> Void
    var onEnded: () -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began, .changed:
            onChanged(recognizer.translation(in: recognizer.view).x)
        case .ended, .cancelled, .failed:
            onEnded()
        default:
            break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        /// Вертикальное движение — не наш жест, отдаём скроллу.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }
    }
}
