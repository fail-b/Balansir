import SwiftUI

/// Поля формы счёта (§4.6): цвет + имя, сегмент типа, кружки цветов, «Баланс … ₽».
/// Общие для шита «Новый счёт» и шага «Где вы храните деньги?» онбординга (§4.9).
/// Карточку-фон и numpad рисует родитель: у шита и онбординга они разные.
struct AccountFormFields: View {
    @Bindable var viewModel: AccountFormViewModel
    var isNameFocused: FocusState<Bool>.Binding
    /// Ввод идёт в баланс (numpad открыт) — поле подсвечено.
    let isBalanceActive: Bool
    /// «Далее» на клавиатуре и тап по балансу — переключиться на numpad.
    let onBalanceTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            nameRow
            kindSegment
            colorRow
            balanceField
        }
    }

    private var nameRow: some View {
        HStack(spacing: Theme.Accounts.textGap) {
            AccountColorCard(
                colorHex: viewModel.selectedColorHex,
                width: Theme.Accounts.colorCardWidth,
                height: Theme.Accounts.colorCardHeight
            )
            TextField(viewModel.namePlaceholder, text: $viewModel.name)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Colors.ink)
                .focused(isNameFocused)
                .submitLabel(.next)
                // «Далее» → к балансу: клавиатура прячется, появляется numpad.
                .onSubmit(onBalanceTap)
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var kindSegment: some View {
        HStack(spacing: 0) {
            ForEach(AccountKind.allCases, id: \.self) { kind in
                let isActive = viewModel.selectedKind == kind
                Button {
                    viewModel.selectedKind = kind
                } label: {
                    Text(kind.title)
                        .font(isActive ? Theme.Font.headline : Theme.Font.body)
                        .foregroundStyle(isActive ? Theme.Colors.ink : Theme.Colors.ink2)
                        .frame(maxWidth: .infinity)
                        .frame(height: Theme.Accounts.segmentHeight)
                        .background {
                            if isActive {
                                Capsule()
                                    .fill(Theme.Colors.card)
                                    .shadow(color: Theme.Colors.shadow, radius: Theme.Accounts.segmentShadowRadius, y: Theme.Accounts.segmentShadowY)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
            }
        }
        .padding(Theme.Spacing.xs)
        .background(Theme.Colors.fill, in: Capsule())
        .animation(reduceMotion ? nil : .snappy, value: viewModel.selectedKind)
    }

    /// Кружки цветов (долг №8: `.buttonStyle(.plain)` — иначе срабатывает не та кнопка).
    private var colorRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(viewModel.colorOptions.enumerated()), id: \.element) { index, hex in
                if index > 0 { Spacer(minLength: 0) }
                Button { viewModel.selectedColorHex = hex } label: {
                    Circle()
                        .fill(Color(hex: hex) ?? Theme.Colors.fallback)
                        .frame(width: Theme.Accounts.colorDot, height: Theme.Accounts.colorDot)
                        .padding(Theme.Accounts.colorRingGap + Theme.Accounts.colorRingWidth)
                        .overlay {
                            if viewModel.isSelected(hex) {
                                Circle().strokeBorder(Theme.Colors.accent, lineWidth: Theme.Accounts.colorRingWidth)
                            }
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Цвет \(index + 1)")
                .accessibilityAddTraits(viewModel.isSelected(hex) ? .isSelected : [])
            }
        }
    }

    /// «Баланс … ₽» — не TextField: системная клавиатура для него не появляется никогда.
    private var balanceField: some View {
        Button(action: onBalanceTap) {
            HStack(spacing: Theme.Spacing.s) {
                Text("Баланс")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Colors.ink2)
                Spacer(minLength: Theme.Spacing.s)
                Text(viewModel.formattedBalance)
                    .font(Theme.Font.bodyAmount)
                    .foregroundStyle(viewModel.isBalanceEmpty ? Theme.Colors.ink2 : Theme.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(Theme.Size.summaryMinScale)
                Text(MoneyFormatter.symbol(for: "RUB"))
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Colors.ink2)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .frame(height: Theme.Accounts.balanceFieldHeight)
            .background(Theme.Colors.fill, in: RoundedRectangle(cornerRadius: Theme.Radius.balanceField))
            .overlay {
                if isBalanceActive {
                    RoundedRectangle(cornerRadius: Theme.Radius.balanceField)
                        .strokeBorder(Theme.Colors.accent, lineWidth: Theme.Accounts.colorRingWidth)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.balanceField))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Баланс \(viewModel.formattedBalance) рублей")
    }
}
