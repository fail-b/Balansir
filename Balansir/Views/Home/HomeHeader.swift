import SwiftUI

/// Шапка Главной с двумя состояниями (§4.1.4):
/// обычное — заголовок месяца + стеклянная капсула (лупа + настройки);
/// поиск — стеклянная строка поиска с фокусом + круглая стеклянная «✕».
/// Лупа морфится в строку поиска через `GlassEffectContainer` + `glassEffectID`.
struct HomeHeader: View {
    @Bindable var viewModel: HomeViewModel
    let monthName: String
    var onOpenSettings: () -> Void

    @FocusState private var isSearchFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Namespace private var glassNamespace

    private var morphAnimation: SwiftUI.Animation? {
        reduceMotion ? nil : Theme.Animation.searchMorph
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
        // Свайп по ленте снимает фокус; если запрос пуст — выходим из поиска.
        .onChange(of: isSearchFocused) { _, focused in
            if !focused && isQueryEmpty {
                withAnimation(morphAnimation) { viewModel.isSearchActive = false }
            }
        }
    }

    // MARK: - Обычное состояние

    private var normalHeader: some View {
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

            HStack(spacing: 0) {
                Button(action: activateSearch) {
                    AppIcon.image(named: AppIcon.search)
                        .font(.system(size: 17))
                        .frame(width: Theme.Size.searchBar, height: Theme.Size.searchBar)
                }
                .buttonStyle(.plain)

                Button(action: onOpenSettings) {
                    AppIcon.image(named: AppIcon.settings)
                        .font(.system(size: 17))
                        .frame(width: Theme.Size.searchBar, height: Theme.Size.searchBar)
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(Theme.Colors.ink)
            .glassEffect()
            .glassEffectID(searchGlassID, in: glassNamespace)
        }
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
                    .focused($isSearchFocused)
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
        isSearchFocused = true
    }

    private func closeSearch() {
        viewModel.searchQuery = ""
        isSearchFocused = false
        withAnimation(morphAnimation) { viewModel.isSearchActive = false }
    }
}
