import SwiftUI

/// Шаг 2 онбординга (§4.9): «Где вы храните деньги?» — добавленные счета (✕), встроенная форма
/// как в шите «Новый счёт» (§4.6), «+ Добавить счёт» и «Готово» внизу.
/// Имя — системная клавиатура, баланс — свой numpad; одновременно видна только одна из них.
struct OnboardingAccountsStep: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @FocusState private var isNameFocused: Bool
    @State private var isNumpadVisible = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text("Where do you keep your money?")
                            .font(Theme.Font.screenTitle)
                            .tracking(Theme.Font.Tracking.screenTitle)
                            .foregroundStyle(Theme.Colors.ink)
                        Text("Add your cards, cash and deposits.")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Colors.ink2)
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    if !viewModel.addedAccounts.isEmpty {
                        addedList
                    }
                    formCard
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.top, Theme.Spacing.xxl)
                .padding(.bottom, Theme.Spacing.l)
                // Тап мимо полей прячет и клавиатуру, и numpad.
                .contentShape(Rectangle())
                .onTapGesture { hideInput() }
            }
            .scrollDismissesKeyboard(.interactively)

            VStack(spacing: Theme.Spacing.l) {
                if isNumpadVisible {
                    NumpadView(layout: .signedAmount) { viewModel.draft.press($0) }
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
                OnboardingPrimaryButton(title: viewModel.finishTitle, isEnabled: viewModel.canFinish) {
                    hideInput()
                    Task { await viewModel.finish() }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.s)
        }
        .animation(reduceMotion ? nil : Theme.Animation.numpadToggle, value: isNumpadVisible)
        .animation(reduceMotion ? nil : .snappy, value: viewModel.addedAccounts)
        // Сразу печатаем имя первого счёта — минимум тапов.
        .onAppear { isNameFocused = true }
        .onChange(of: isNameFocused) { _, focused in
            if focused { isNumpadVisible = false }
        }
    }

    private func showNumpad() {
        isNameFocused = false
        isNumpadVisible = true
    }

    private func hideInput() {
        isNameFocused = false
        isNumpadVisible = false
    }

    // MARK: - Добавленные счета

    private var addedList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.addedAccounts) { account in
                if account.id != viewModel.addedAccounts.first?.id {
                    Rectangle()
                        .fill(Theme.Colors.separator)
                        .frame(height: Theme.Size.hairline)
                        .padding(.leading, Theme.Accounts.separatorInset)
                }
                HStack(spacing: 0) {
                    AccountRow(account: account, balance: account.initialBalance)
                    Button {
                        Task { await viewModel.removeAccount(account.id) }
                    } label: {
                        AppIcon.image(named: AppIcon.close)
                            .font(Theme.Font.headline)
                            .foregroundStyle(Theme.Colors.ink2)
                            .frame(width: Theme.Size.searchBar, height: Theme.Size.searchBar)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete account \(account.name)")
                }
                .padding(.trailing, Theme.Spacing.xs)
                .transition(.opacity)
            }
        }
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    // MARK: - Форма нового счёта

    private var formCard: some View {
        VStack(spacing: Theme.Spacing.l) {
            AccountFormFields(
                viewModel: viewModel.draft,
                isNameFocused: $isNameFocused,
                isBalanceActive: isNumpadVisible,
                onBalanceTap: showNumpad
            )
            addButton
        }
        .padding(Theme.Spacing.l)
        .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var addButton: some View {
        Button {
            hideInput()
            Task { await viewModel.addAccount() }
        } label: {
            HStack(spacing: Theme.Spacing.s) {
                AppIcon.image(named: AppIcon.add)
                Text("Add Account")
            }
            .font(Theme.Font.actionButton)
            .foregroundStyle(Theme.Colors.accent)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.Accounts.balanceFieldHeight)
            .background(Theme.Colors.fill, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.draft.canSave)
        .opacity(viewModel.draft.canSave ? 1 : Theme.Accounts.disabledOpacity)
    }
}
