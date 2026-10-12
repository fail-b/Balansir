import SwiftUI

/// Шаг 1 онбординга (§4.9): пример hero-карточки, «Balansir», описание, «Начать».
struct OnboardingIntroStep: View {
    let viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            demoCard
            Spacer()
            Text(verbatim: "Balansir")
                .font(Theme.Font.onboardingBrand)
                .foregroundStyle(Theme.Colors.ink)
            Text("All your cards and cash in one place. Logging an expense takes seconds.")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.m)
            OnboardingPrimaryButton(title: String(localized: "Get Started")) { viewModel.start() }
                .padding(.top, Theme.Spacing.xxl)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)
    }

    /// Пример карточки — демо-данные из VM, не из базы.
    private var demoCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: Theme.Row.textSpacing) {
                    Text(viewModel.demoTitle)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Colors.ink2)
                    Text(MoneyFormatter.format(viewModel.demoExpense))
                        .font(Theme.Font.heroAmount)
                        .tracking(Theme.Font.Tracking.heroAmount)
                        .foregroundStyle(Theme.Colors.ink)
                }
                Spacer()
                Text(verbatim: "+\(MoneyFormatter.format(viewModel.demoIncome))")
                    .font(Theme.Font.bodyAmount)
                    .foregroundStyle(Theme.Colors.income)
            }
            demoBar
        }
        .padding(.horizontal, Theme.Onboarding.demoCardHorizontalPadding)
        .padding(.vertical, Theme.Onboarding.demoCardVerticalPadding)
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.hero))
        .shadow(color: Theme.Colors.shadow, radius: Theme.Onboarding.demoShadowRadius, y: Theme.Onboarding.demoShadowY)
        .accessibilityElement(children: .combine)
    }

    private var demoBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Theme.Onboarding.demoBarRadius)
                    .fill(Theme.Colors.fill)
                HStack(spacing: Theme.Onboarding.demoBarGap) {
                    ForEach(viewModel.demoSegments.indices, id: \.self) { i in
                        let segment = viewModel.demoSegments[i]
                        RoundedRectangle(cornerRadius: Theme.Onboarding.demoBarRadius)
                            .fill(Color(hex: segment.colorHex) ?? Theme.Colors.fallback)
                            .frame(width: geo.size.width * segment.fraction)
                    }
                }
            }
        }
        .frame(height: Theme.Onboarding.demoBarHeight)
    }
}
