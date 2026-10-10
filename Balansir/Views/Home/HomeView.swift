import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @Binding var selectedTab: AppTab
    @Binding var isScrolled: Bool

    @State private var settingsVM: SettingsViewModel?
    @State private var editEntryVM: AddEntryViewModel?

    // Жест «потянуть вниз» → поиск (§4.1.4) — только на геометрии и фазе скролла, без DragGesture
    // (DragGesture поверх ScrollView ломал прокрутку). overscroll — оттяжка за верхний край.
    @State private var overscroll: CGFloat = 0
    @State private var isInteracting = false
    @State private var reachedThreshold = false
    // Закрытие поиска: контент короче экрана (можно ли по нему скроллить).
    @State private var isScrollable = false
    // Фокус строки поиска живёт здесь, чтобы закрытие могло снять его явно (скрыть клавиатуру).
    @FocusState private var isSearchFocused: Bool
    // Закрытие поиска свайпом откладывается до остановки скролла: менять раскладку
    // (вставлять hero, убирать пустую зону) под пальцем — это и давало рывок.
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var pendingClose = false
    @State private var scrollPosition = ScrollPosition(edge: .top)
    // Высота hero вместе с верхним отступом — последняя измеренная (в поиске hero нет в раскладке).
    @State private var heroHeight: CGFloat = 0
    // Текущее смещение ленты. Класс без наблюдения: запись не перерисовывает экран на каждом кадре.
    @State private var scrollMetrics = ScrollMetrics()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Прогресс жеста 0…1; в режиме поиска жест выключен.
    private var pullProgress: CGFloat {
        guard !viewModel.isSearchActive else { return 0 }
        return min(overscroll / Theme.Pull.threshold, 1)
    }

    var body: some View {
        // proxy уже учитывает клавиатуру: в поиске лента тянется ровно до неё.
        GeometryReader { proxy in
            feed(minHeight: proxy.size.height)
        }
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

    // MARK: - Лента

    /// Скролл Главной с жестами поиска: «потянуть вниз» — открыть, свайп вверх — закрыть.
    private func feed(minHeight: CGFloat) -> some View {
        ScrollView {
            feedContent(minHeight: minHeight)
        }
        // В поиске короткий контент не отскакивает (иначе свайп вверх «дёргает» экран).
        // Вне поиска отскок нужен всегда — на нём держится «потянуть вниз».
        .scrollBounceBehavior(viewModel.isSearchActive ? .basedOnSize : .always)
        .scrollDismissesKeyboard(.immediately)
        .clearsBottomAccessory()
        .reportsScroll(to: $isScrolled)
        .reportsOverscroll(to: $overscroll)
        .reportsScrollable(to: $isScrollable)
        .scrollPosition($scrollPosition)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            scrollMetrics.offset = offset
        }
        .onChange(of: isSearchFocused) { _, focused in
            handleSearchFocusChange(focused)
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            if !searchQueryEmpty { pendingClose = false }
        }
        .onScrollPhaseChange { oldPhase, newPhase in
            handleScrollPhase(from: oldPhase, to: newPhase)
        }
        .onChange(of: overscroll) { _, value in
            // Порог считаем, только пока палец на экране (не во время отскока назад).
            guard isInteracting, !viewModel.isSearchActive else { return }
            reachedThreshold = value >= Theme.Pull.threshold
        }
        .sensoryFeedback(trigger: reachedThreshold) { _, reached in
            reached ? .impact(weight: .medium) : nil
        }
    }

    /// Контент ленты + пустая зона под ней (только в поиске), тап по которой закрывает поиск.
    private func feedContent(minHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            feedItems
                .padding(.bottom, Theme.Spacing.s)

            // Шапка, счета и операции — выше и в эту зону не входят.
            if viewModel.isSearchActive {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture { closeSearch() }
            }
        }
        // В поиске контент не ниже видимой области — пустая зона растягивается до клавиатуры.
        .frame(minHeight: viewModel.isSearchActive ? minHeight : 0, alignment: .top)
        .contentShape(Rectangle())
        // Свайп вверх закрывает поиск, если контент короче экрана. Жест включён только тогда:
        // в остальное время на ленте нет ни одного DragGesture, скролл работает нативно.
        .simultaneousGesture(
            swipeUpToClose,
            including: viewModel.isSearchActive && !isScrollable ? .all : .subviews
        )
    }

    private var feedItems: some View {
        VStack(alignment: .leading, spacing: 0) {
            HomeHeader(
                viewModel: viewModel,
                monthName: currentMonthName,
                pullProgress: pullProgress,
                searchFocus: $isSearchFocused,
                onOpenSettings: { settingsVM = viewModel.makeSettingsViewModel() }
            )

            if !viewModel.isSearchActive {
                heroCard
                    .padding(.top, Theme.Spacing.s)
                    .padding(.horizontal, Theme.Spacing.l)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { heroHeight = $0 }
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
    }

    private var swipeUpToClose: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard viewModel.isSearchActive, !isScrollable else { return }
                let dy = value.translation.height
                guard dy < -Theme.Pull.threshold, abs(dy) > abs(value.translation.width) else { return }
                closeSearch()
            }
    }

    /// Жест «потянуть вниз» → поиск (§4.1.4): палец отпущен (выход из `.interacting`)
    /// при оттяжке за порог — активируем поиск; иначе лента сама отскакивает назад.
    private func handleScrollPhase(from oldPhase: ScrollPhase, to newPhase: ScrollPhase) {
        scrollPhase = newPhase
        isInteracting = newPhase == .interacting
        if newPhase == .idle, pendingClose {
            pendingClose = false
            closeSearchKeepingPosition()
        }
        guard oldPhase == .interacting, newPhase != .interacting else { return }
        let shouldActivate = reachedThreshold && !viewModel.isSearchActive
        reachedThreshold = false
        if shouldActivate { activateSearchFromGesture() }
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

    /// Активация поиска по жесту «потянуть вниз»: как по тапу + запрос фокуса в шапке.
    private func activateSearchFromGesture() {
        withAnimation(reduceMotion ? nil : Theme.Animation.searchMorph) {
            viewModel.isSearchActive = true
        }
        viewModel.shouldFocusSearch = true
    }

    /// Закрытие поиска: тап по пустому месту или свайп вверх (как ✕ в шапке).
    /// Фокус снимаем явно — клавиатура скрывается сразу, а не при удалении поля.
    private func closeSearch() {
        isSearchFocused = false
        viewModel.searchQuery = ""
        withAnimation(reduceMotion ? nil : Theme.Animation.searchMorph) {
            viewModel.isSearchActive = false
        }
    }

    /// Свайп по ленте снимает фокус (`scrollDismissesKeyboard`); при пустом запросе выходим из поиска,
    /// но только когда скролл остановился. Тап по полю до остановки отменяет выход.
    private func handleSearchFocusChange(_ focused: Bool) {
        if focused {
            pendingClose = false
            return
        }
        guard viewModel.isSearchActive, searchQueryEmpty else { return }
        if scrollPhase == .idle {
            closeSearchKeepingPosition()
        } else {
            pendingClose = true
        }
    }

    /// Выход из поиска без сдвига видимых строк: если лента прокручена, hero вставляется
    /// над экраном без анимации, а смещение увеличивается на его высоту — строки остаются на месте.
    /// У самого верха — обычная анимация (hero выезжает сверху).
    private func closeSearchKeepingPosition() {
        guard viewModel.isSearchActive, searchQueryEmpty else { return }
        let offset = scrollMetrics.offset
        guard offset > 1, heroHeight > 0 else {
            closeSearch()
            return
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            viewModel.isSearchActive = false
            scrollPosition.scrollTo(y: offset + heroHeight)
        }
    }

    private var currentMonthName: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL"
        f.locale = Locale(identifier: "ru_RU")
        let s = f.string(from: Date())
        return s.prefix(1).uppercased() + s.dropFirst()
    }
}

/// Хранилище смещения ленты без наблюдения SwiftUI (см. `scrollMetrics`).
private final class ScrollMetrics {
    var offset: CGFloat = 0
}
