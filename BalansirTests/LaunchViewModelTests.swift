import Testing
@testable import Balansir

@Suite("LaunchViewModel")
@MainActor
struct LaunchViewModelTests {

    @Test("Сплэш виден, пока не закончились и анимация, и подготовка данных")
    func splashWaitsForAnimationAndData() async {
        let vm = LaunchViewModel()
        #expect(vm.isSplashVisible)

        vm.animationFinished()
        #expect(vm.isSplashVisible)

        await vm.prepare()
        #expect(!vm.isSplashVisible)
    }

    @Test("Данные готовы раньше анимации — сплэш ждёт анимацию")
    func splashWaitsForAnimationWhenDataReadyFirst() async {
        let vm = LaunchViewModel()
        await vm.prepare()
        #expect(vm.isSplashVisible)

        vm.animationFinished()
        #expect(!vm.isSplashVisible)
    }
}
