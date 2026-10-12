import Foundation

/// Экран запуска: сплэш держится, пока не закончились и анимация, и подготовка данных.
/// Создаётся один раз в `BalansirApp` и живёт всё время жизни процесса, поэтому сплэш
/// показывается только при холодном старте (первый запуск или после выгрузки из памяти),
/// а не при возврате из фона и не в новых окнах на iPad.
@Observable
final class LaunchViewModel {
    private(set) var isAnimationFinished = false
    private(set) var isDataReady = false

    var isSplashVisible: Bool { !(isAnimationFinished && isDataReady) }

    func animationFinished() {
        isAnimationFinished = true
    }

    /// Подготовка данных до показа приложения (идёт параллельно с анимацией).
    /// Сейчас данные локальные (Core Data), экраны загружают их сами под сплэшем — ждать нечего.
    /// Сюда добавится загрузка обновлений из облака.
    func prepare() async {
        isDataReady = true
    }
}
