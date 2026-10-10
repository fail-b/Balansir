import SwiftUI

/// Шапка Главной с двумя состояниями (§4.1.4):
/// обычное — заголовок месяца + стеклянная капсула (лупа + настройки);
/// поиск — стеклянная строка поиска с фокусом + круглая стеклянная «✕».
/// Лупа морфится в строку поиска через `GlassEffectContainer` + `glassEffectID`.
struct HomeHeader: View {
    @Bindable var viewModel: HomeViewModel
    let monthName: String
    /// Прогресс жеста «потянуть вниз» 0…1 (§4.1.4): растягивает капсулу лупы.
    var pullProgress: CGFloat = 0
    /// Фокус строки поиска (владелец — HomeView, чтобы закрывать поиск тапом/свайпом).
    var searchFocus: FocusState<Bool>.Binding
    var onOpenSettings: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Namespace private var glassNamespace

    private var morphAnimation: SwiftUI.Animation? {
        reduceMotion ? nil : Theme.Animation.searchMorph
    }

    // Reduce Motion → без растягивания по жесту (только активация по порогу).
    private var stretch: CGFloat {
        reduceMotion ? 0 : pullProgress
    }

    // Один общий id под морфинг: капсула лупы ↔ строка поиска.
    private let searchGlassID = "homeSearchGlass"

    var body: some View {
        GlassEffectContainer {
            if viewModel.isSearchActive {
                searchModeHeader
            } else {
                normalHeader
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.s)
        // Выход из поиска при потере фокуса — в HomeView: там известна фаза скролла.
        // Активация жестом просит фокус здесь (FocusState живёт в шапке).
        .onChange(of: viewModel.shouldFocusSearch) { _, should in
            if should {
                searchFocus.wrappedValue = true
                viewModel.shouldFocusSearch = false
            }
        }
    }

    // MARK: - Обычное состояние

    private var normalHeader: some View {
        GeometryReader { geo in
            // Капсула лупы растёт от обычной ширины (лупа + настройки) до полной ширины шапки.
            let baseWidth = Theme.Size.searchBar * 2
            let capsuleWidth = baseWidth + stretch * (geo.size.width - baseWidth)

            ZStack {
                HStack {
                    Button {} label: {
                        HStack(spacing: 4) {
                            Text(monthName)
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
                }
                .opacity(1 - stretch)

                HStack {
                    Spacer()
                    searchCapsule(width: capsuleWidth)
                }
            }
        }
        .frame(height: Theme.Size.searchBar)
    }

    private func searchCapsule(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Button(action: activateSearch) {
                AppIcon.image(named: AppIcon.search)
                    .font(.system(size: 17))
                    .scaleEffect(pullProgress >= 1 && !reduceMotion ? Theme.Pull.magnifierScaleActive : 1)
                    .animation(morphAnimation, value: pullProgress >= 1)
                    .frame(width: Theme.Size.searchBar, height: Theme.Size.searchBar)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            Button(action: onOpenSettings) {
                AppIcon.image(named: AppIcon.settings)
                    .font(.system(size: 17))
                    .frame(width: Theme.Size.searchBar, height: Theme.Size.searchBar)
            }
            .buttonStyle(.plain)
            .opacity(1 - stretch)
        }
        .foregroundStyle(Theme.Colors.ink)
        .frame(width: width, height: Theme.Size.searchBar)
        .glassEffect()
        .glassEffectID(searchGlassID, in: glassNamespace)
    }

    // MARK: - Режим поиска

    private var searchModeHeader: some View {
        HStack(spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                AppIcon.image(named: AppIcon.search)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.Colors.ink2)

                TextField("Категория, счёт или заметка", text: $viewModel.searchQuery)
                    .font(Theme.Font.searchField)
                    .foregroundStyle(Theme.Colors.ink)
                    .focused(searchFocus)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !isQueryEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        AppIcon.image(named: AppIcon.closeCircle)
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.Colors.ink2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .frame(height: Theme.Size.searchBar)
            .frame(maxWidth: .infinity)
            .glassEffect()
            .glassEffectID(searchGlassID, in: glassNamespace)

            Button(action: closeSearch) {
                AppIcon.image(named: AppIcon.close)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(width: Theme.Size.searchBar, height: Theme.Size.searchBar)
            }
            .buttonStyle(.plain)
            .glassEffect()
        }
    }

    // MARK: - Действия

    private var isQueryEmpty: Bool {
        viewModel.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func activateSearch() {
        withAnimation(morphAnimation) { viewModel.isSearchActive = true }
        searchFocus.wrappedValue = true
    }

    private func closeSearch() {
        searchFocus.wrappedValue = false
        viewModel.searchQuery = ""
        withAnimation(morphAnimation) { viewModel.isSearchActive = false }
    }
}
