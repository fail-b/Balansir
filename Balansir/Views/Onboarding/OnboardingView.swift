import SwiftUI

/// Онбординг (§4.9): при первом запуске и из Настроек («Показать приветствие»).
/// Закрывается только «Готово» или «Пропустить» (`fullScreenCover`, свайпом не закрыть).
struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            header
            switch viewModel.step {
            case .intro:
                OnboardingIntroStep(viewModel: viewModel)
                    .transition(stepTransition(edge: .leading))
            case .accounts:
                OnboardingAccountsStep(viewModel: viewModel)
                    .transition(stepTransition(edge: .trailing))
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
        .animation(reduceMotion ? nil : .snappy, value: viewModel.step)
        .onChange(of: viewModel.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .alert("Ошибка", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func stepTransition(edge: Edge) -> AnyTransition {
        reduceMotion ? .opacity : .move(edge: edge).combined(with: .opacity)
    }

    // MARK: - Шапка: «‹» · прогресс · «Пропустить»

    private var header: some View {
        HStack(spacing: Theme.Spacing.l) {
            // На шаге 1 кнопка скрыта, но место держит — прогресс не прыгает.
            Button { viewModel.back() } label: {
                AppIcon.image(named: AppIcon.back)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(width: Theme.Size.searchBar, height: Theme.Size.searchBar)
                    .glassEffect(in: .circle)
            }
            .buttonStyle(.plain)
            .opacity(viewModel.canGoBack ? 1 : 0)
            .disabled(!viewModel.canGoBack)
            .accessibilityLabel("Назад")

            HStack(spacing: Theme.Spacing.s) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    Capsule()
                        .fill(viewModel.isProgressFilled(step) ? Theme.Colors.accent : Theme.Colors.fill2)
                        .frame(height: Theme.Onboarding.progressHeight)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Шаг \(viewModel.step.rawValue + 1) из \(OnboardingStep.allCases.count)")

            Button("Пропустить") {
                Task { await viewModel.skip() }
            }
            .font(Theme.Font.body)
            .foregroundStyle(Theme.Colors.ink2)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.s)
    }
}

/// Кнопка-действие внизу экрана во всю ширину («Начать», «Готово»).
struct OnboardingPrimaryButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Font.actionButton)
                .foregroundStyle(Theme.Colors.onColor)
                .lineLimit(1)
                .minimumScaleFactor(Theme.Size.summaryMinScale)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.Accounts.addButtonHeight)
                .background(Theme.Colors.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        // Без затемнения: по макету «Добавьте хотя бы один счёт» — та же акцентная кнопка-подсказка.
        .disabled(!isEnabled)
    }
}
