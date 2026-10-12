import SwiftUI

/// Шит «Новый счёт» / «Изменить счёт» (§4.6). Нативный шит высотой по содержимому.
/// Имя — системная клавиатура, баланс — свой numpad с «−»; одновременно видна только одна из них.
struct AccountFormView: View {
    @Bindable var viewModel: AccountFormViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Фокус поля имени. Пока он есть — системная клавиатура, numpad спрятан.
    @FocusState private var isNameFocused: Bool
    /// Высота содержимого — по ней подбирается высота шита.
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Theme.Colors.background)
            .presentationDetents(contentHeight > 0 ? [.height(contentHeight)] : [.medium])
            .presentationCornerRadius(Theme.Radius.accountSheet)
            .presentationBackground(Theme.Colors.background)
            .presentationDragIndicator(.visible)
            // Новый счёт: сразу печатаем имя (минимум тапов). При редактировании — сразу numpad.
            .onAppear { if !viewModel.isEditing { isNameFocused = true } }
            .alert("Ошибка", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }

    private var content: some View {
        VStack(spacing: Theme.Spacing.l) {
            header
            card
            if !isNameFocused {
                NumpadView(layout: .signedAmount) { viewModel.press($0) }
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
            addButton
        }
        .animation(reduceMotion ? nil : Theme.Animation.numpadToggle, value: isNameFocused)
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.xl)
        .padding(.bottom, Theme.Spacing.s)
        // Тап мимо поля имени прячет системную клавиатуру и показывает numpad.
        .contentShape(Rectangle())
        .onTapGesture { isNameFocused = false }
    }

    // MARK: - Шапка

    private var header: some View {
        HStack {
            Text(viewModel.title)
                .font(Theme.Font.accountSheetTitle)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            Button { dismiss() } label: {
                AppIcon.image(named: AppIcon.close)
                    .font(Theme.Font.headline)
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(width: Theme.Size.searchBar, height: Theme.Size.searchBar)
                    .glassEffect(in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Закрыть")
        }
        .padding(.leading, Theme.Spacing.xs)
    }

    // MARK: - Карточка формы

    private var card: some View {
        VStack(spacing: Theme.Spacing.l) {
            nameRow
            kindSegment
            colorRow
            balanceField
        }
        .padding(Theme.Spacing.l)
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
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
                .focused($isNameFocused)
                .submitLabel(.next)
                // «Далее» → к балансу: клавиатура прячется, появляется numpad.
                .onSubmit { isNameFocused = false }
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
        Button { isNameFocused = false } label: {
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
                // Numpad открыт — поле подсвечено: видно, куда идёт ввод.
                if !isNameFocused {
                    RoundedRectangle(cornerRadius: Theme.Radius.balanceField)
                        .strokeBorder(Theme.Colors.accent, lineWidth: Theme.Accounts.colorRingWidth)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.balanceField))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Баланс \(viewModel.formattedBalance) рублей")
    }

    // MARK: - Кнопка

    private var addButton: some View {
        Button {
            Task {
                await viewModel.save()
                if viewModel.errorMessage == nil { dismiss() }
            }
        } label: {
            Text(viewModel.actionTitle)
                .font(Theme.Font.actionButton)
                .foregroundStyle(Theme.Colors.onColor)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.Accounts.addButtonHeight)
                .background(Theme.Colors.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1 : Theme.Accounts.disabledOpacity)
    }
}
