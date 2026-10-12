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
    /// Фокус с имени снимаем мы сами («Далее», тап мимо поля, тап по балансу).
    /// Если фокус пропал без этого флага — клавиатуру убрал свайп шита вниз: закрываем шит сразу.
    @State private var isFocusChangeIntentional = false
    /// Шит уже закрывается (крестик, сохранение) — потерю фокуса не обрабатываем.
    @State private var isClosing = false

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
            // Свайп вниз при открытой клавиатуре: iOS сначала прячет клавиатуру, и шит остаётся.
            // Ловим эту «непрошеную» потерю фокуса и закрываем шит — одно движение вместо двух.
            .onChange(of: isNameFocused) { wasFocused, isFocused in
                // Алерт ошибки тоже снимает фокус — это не свайп.
                guard wasFocused, !isFocused, !isClosing, viewModel.errorMessage == nil else { return }
                if isFocusChangeIntentional {
                    isFocusChangeIntentional = false
                } else {
                    close()
                }
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
        .onTapGesture { switchToNumpad() }
    }

    // MARK: - Фокус и закрытие

    /// Убрать системную клавиатуру и показать numpad (осознанное действие, шит не закрывается).
    private func switchToNumpad() {
        guard isNameFocused else { return }
        isFocusChangeIntentional = true
        isNameFocused = false
    }

    private func close() {
        isClosing = true
        dismiss()
    }

    // MARK: - Шапка

    private var header: some View {
        HStack {
            Text(viewModel.title)
                .font(Theme.Font.accountSheetTitle)
                .foregroundStyle(Theme.Colors.ink)
            Spacer()
            Button { close() } label: {
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
        AccountFormFields(
            viewModel: viewModel,
            isNameFocused: $isNameFocused,
            // Numpad открыт — поле баланса подсвечено: видно, куда идёт ввод.
            isBalanceActive: !isNameFocused,
            onBalanceTap: switchToNumpad
        )
        .padding(Theme.Spacing.l)
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: - Кнопка

    private var addButton: some View {
        Button {
            Task {
                await viewModel.save()
                if viewModel.errorMessage == nil { close() }
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
