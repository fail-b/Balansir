import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @Binding var selectedTab: AppTab
    @Binding var isScrolled: Bool

    @State private var settingsVM: SettingsViewModel?
    @State private var editEntryVM: AddEntryViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HomeHeader(
                    viewModel: viewModel,
                    monthName: currentMonthName,
                    onOpenSettings: { settingsVM = viewModel.makeSettingsViewModel() }
                )

                if !viewModel.isSearchActive {
                    heroCard
                        .padding(.top, Theme.Spacing.s)
                        .padding(.horizontal, Theme.Spacing.l)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                accountFilterChips
                    .padding(.top, Theme.Spacing.xl)

                if viewModel.entriesByDay.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.entriesByDay) { group in
                        DaySection(
                            group: group,
                            onTap: { entry in
                                editEntryVM = viewModel.makeAddEntryViewModel(for: entry)
                            },
                            onDelete: { entry in
                                Task { await viewModel.delete(entry: entry) }
                            }
                        )
                        .padding(.top, Theme.Spacing.xl)
                        .padding(.horizontal, Theme.Spacing.l)
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.s)
        }
        .scrollDismissesKeyboard(.immediately)
        .reportsScroll(to: $isScrolled)
        .background(Theme.Colors.background)
        .sheet(item: $settingsVM, onDismiss: { Task { await viewModel.load() } }) { vm in
            SettingsView(viewModel: vm, isScrolled: .constant(false))
        }
        .sheet(item: $editEntryVM, onDismiss: { Task { await viewModel.load() } }) { vm in
            AddEntryView(viewModel: vm)
        }
        .task { await viewModel.load() }
        .alert("Ошибка", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        Button {
            selectedTab = .statistics
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Расходы")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Colors.ink2)
                        Text(MoneyFormatter.format(viewModel.monthExpense))
                            .font(Theme.Font.heroAmount)
                            .tracking(Theme.Font.Tracking.heroAmount)
                            .foregroundStyle(Theme.Colors.ink)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Доходы")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Colors.ink2)
                        Text("+\(MoneyFormatter.format(viewModel.monthIncome))")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.Colors.income)
                    }
                }

                heroProgressBar

                if !viewModel.heroLegend.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(viewModel.heroLegend) { segment in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: segment.colorHex) ?? Theme.Colors.fallback)
                                    .frame(width: 7, height: 7)
                                Text("\(segment.name) \(segment.percent)%")
                                    .font(Theme.Font.time)
                                    .foregroundStyle(Theme.Colors.ink2)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Theme.Colors.card, in: RoundedRectangle(cornerRadius: Theme.Radius.hero))
        }
        .buttonStyle(.plain)
    }

    private var heroProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Theme.Colors.fill)

                HStack(spacing: 2) {
                    ForEach(viewModel.heroSegments) { segment in
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: segment.colorHex) ?? Theme.Colors.fallback)
                            .frame(width: geo.size.width * CGFloat(segment.fraction))
                            .animation(.easeOut(duration: 0.5), value: segment.fraction)
                    }
                }
            }
        }
        .frame(height: 10)
    }

    // MARK: - Account Filter Chips

    private var accountFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                AccountChip(
                    title: "Все",
                    colorHex: nil,
                    balance: viewModel.totalBalance,
                    isActive: viewModel.selectedAccountId == nil
                ) {
                    viewModel.selectedAccountId = nil
                }
                ForEach(viewModel.accounts) { account in
                    AccountChip(
                        title: account.name,
                        colorHex: account.colorHex,
                        balance: viewModel.balances[account.id] ?? 0,
                        isActive: viewModel.selectedAccountId == account.id
                    ) {
                        viewModel.selectedAccountId = viewModel.selectedAccountId == account.id ? nil : account.id
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        Group {
            if viewModel.isSearchActive && !searchQueryEmpty {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Ничего не найдено")
                        .font(Theme.Font.sheetTitle)
                        .foregroundStyle(Theme.Colors.ink)
                    Text("Попробуйте другое слово")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Colors.ink2)
                }
            } else {
                Text(viewModel.selectedAccountId == nil
                     ? "Операций пока нет. Нажмите «+», чтобы добавить первую."
                     : "По этому счёту операций нет.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Colors.ink2)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, Theme.Spacing.l)
    }

    private var searchQueryEmpty: Bool {
        viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Helpers

    private var currentMonthName: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL"
        f.locale = Locale(identifier: "ru_RU")
        let s = f.string(from: Date())
        return s.prefix(1).uppercased() + s.dropFirst()
    }
}
