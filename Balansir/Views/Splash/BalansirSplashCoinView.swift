import SwiftUI

/// Анимация запуска «Монета» (от дизайнера, 2026-10-12): монета падает, дважды переворачивается,
/// в неё влетают три монетки, она делится на половинки знака, появляется слово «balansir».
/// ~1,5 с, последний кадр статичен. При «Уменьшении движения» сразу показывается последний кадр.
/// Константы — `Theme.Splash`, цвета — `Theme.Colors.splash*`, шрифт — `Theme.Font.splashWordmark`.
struct BalansirSplashCoinView: View {
    var showsWordmark = true
    var onFinished: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dropped = false
    @State private var spun = false
    @State private var dotsShown = false
    @State private var deposited = false
    @State private var split = false
    @State private var wordIn = false

    /// Фаза монеток: 0 — скрыты, 1 — появились, 2 — влетели в знак.
    private var dotPhase: Int { deposited ? 2 : (dotsShown ? 1 : 0) }
    private var diameter: CGFloat { Theme.Splash.markDiameter }
    private var gap: CGFloat { diameter * Theme.Splash.markGapRatio }

    var body: some View {
        ZStack {
            Theme.Colors.splashBackground.ignoresSafeArea()
            VStack(spacing: Theme.Splash.wordmarkSpacing) {
                ZStack {
                    ForEach(Theme.Splash.dotStarts.indices, id: \.self) { i in
                        dot(index: i)
                    }
                    VStack(spacing: split ? gap : 0) {
                        half(top: true)
                        half(top: false).opacity(split ? Theme.Splash.lowerHalfOpacity : 1)
                    }
                    .rotation3DEffect(.degrees(spun ? Theme.Splash.spinDegrees : 0),
                                      axis: (0, 1, 0),
                                      perspective: Theme.Splash.spinPerspective)
                    .offset(y: dropped ? 0 : -Theme.Splash.dropHeight)
                }
                .frame(width: diameter, height: diameter + gap)

                if showsWordmark {
                    // Название бренда не переводится (задача 10) — verbatim, мимо String Catalog.
                    Text(verbatim: "balansir")
                        .font(Theme.Font.splashWordmark)
                        .tracking(Theme.Splash.wordmarkTracking)
                        .foregroundStyle(Theme.Colors.splashText)
                        .opacity(wordIn ? 1 : 0)
                        .offset(y: wordIn ? 0 : Theme.Splash.wordmarkRise)
                }
            }
        }
        .task { await run() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "Balansir"))
    }

    private func dot(index i: Int) -> some View {
        let delay = Double(i) * Theme.Splash.dotStagger
        return Circle()
            .fill(Theme.Colors.splashMark)
            .frame(width: Theme.Splash.dotSize, height: Theme.Splash.dotSize)
            .scaleEffect(deposited ? Theme.Splash.dotDepositScale : (dotsShown ? 1 : 0))
            .offset(deposited ? Theme.Splash.dotTarget : Theme.Splash.dotStarts[i])
            .opacity(deposited ? 0 : (dotsShown ? 1 : 0))
            .animation(deposited
                       ? Theme.Splash.dotDepositAnimation.delay(delay)
                       : Theme.Splash.dotAppearAnimation.delay(delay),
                       value: dotPhase)
    }

    private func half(top: Bool) -> some View {
        Circle()
            .fill(Theme.Colors.splashMark)
            .frame(width: diameter, height: diameter)
            .frame(width: diameter, height: diameter / 2, alignment: top ? .top : .bottom)
            .clipped()
    }

    private func run() async {
        if reduceMotion {
            dropped = true; spun = true; deposited = true; split = true; wordIn = true
            onFinished?()
            return
        }
        withAnimation(Theme.Splash.dropAnimation) { dropped = true }
        try? await Task.sleep(for: .milliseconds(Theme.Splash.dropPause))
        withAnimation(Theme.Splash.spinAnimation) { spun = true }
        dotsShown = true
        try? await Task.sleep(for: .milliseconds(Theme.Splash.spinPause))
        deposited = true
        withAnimation(Theme.Splash.splitAnimation) { split = true }
        try? await Task.sleep(for: .milliseconds(Theme.Splash.splitPause))
        withAnimation(Theme.Splash.wordmarkAnimation) { wordIn = true }
        try? await Task.sleep(for: .milliseconds(Theme.Splash.wordmarkPause))
        onFinished?()
    }
}

#Preview { BalansirSplashCoinView() }
