import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @Binding var selectedTab: AppTab
    @Binding var isScrolled: Bool

    @State private var settingsVM: SettingsViewModel?
    @State private var showingSettings = false
    @State private var editEntryVM: AddEntryViewModel?
    @State private var showingEditEntry = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                headerView

                heroCard
                    .padding(.top, Theme.Spacing.s)
                    .padding(.horizontal, Theme.Spacing.l)

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
                                showingEditEntry = true
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
        .reportsScroll(to: $isScrolled)
        .background(Theme.Colors.background)
        .sheet(isPresented: $showingSettings, onDismiss: { Task { await viewModel.load() } }) {
            if let vm = settingsVM {
                SettingsView(viewModel: vm, isScrolled: .constant(false))
            }
        }
        .sheet(isPresented: $showingEditEntry, onDismiss: { Task { await viewModel.load() } }) {
            if let vm = editEntryVM {
                AddEntryView(viewModel: vm)
            }
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

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Button { } label: {
                HStack(spacing: 4) {
                    Text(currentMonthName)
                        .font(Theme.Font.screenTitle)
                        .tracking(Theme.Font.Tracking.screenTitle)
                        .foregroundStyle(Theme.Colors.ink)
                    AppIcon.image(named: AppIcon.chevronDown)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink2)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 0) {
                Button {
                    selectedTab = .transactions
                } label: {
                    AppIcon.image(named: AppIcon.search)
                        .font(.system(size: 17))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                Button {
                    settingsVM = viewModel.makeSettingsViewModel()
                    showingSettings = true
                } label: {
                    AppIcon.image(named: AppIcon.settings)
                        .font(.system(size: 17))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(Theme.Colors.ink)
            .glassEffect()
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)
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
            HStack(spacing: 8) {
                chipButton(title: "Все", isActive: viewModel.selectedAccountId == nil, colorHex: nil) {
                    viewModel.selectedAccountId = nil
                }
                ForEach(viewModel.accounts) { account in
                    chipButton(
                        title: account.name,
                        isActive: viewModel.selectedAccountId == account.id,
                        colorHex: account.colorHex
                    ) {
                        viewModel.selectedAccountId = viewModel.selectedAccountId == account.id ? nil : account.id
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }

    private func chipButton(title: String, isActive: Bool, colorHex: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let hex = colorHex {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: hex) ?? Theme.Colors.fallback)
                        .frame(width: 12, height: 8)
                }
                Text(title)
                    .font(.system(size: 15, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Theme.Colors.background : Theme.Colors.ink)
            }
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Capsule().fill(isActive ? Theme.Colors.ink : Theme.Colors.card))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        Text(viewModel.selectedAccountId == nil
             ? "Операций пока нет. Нажмите «+», чтобы добавить первую."
             : "По этому счёту операций нет.")
            .font(.subheadline)
            .foregroundStyle(Theme.Colors.ink2)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
            .padding(.horizontal, Theme.Spacing.l)
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
