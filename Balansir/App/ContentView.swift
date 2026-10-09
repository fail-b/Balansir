import SwiftUI

enum AppTab: Hashable {
    case home, statistics, accounts
    /// Не экран, а кнопка «+» справа от таб-бара (нативная «отдельная» вкладка iOS 26).
    /// Выбрать её нельзя — тап открывает шит новой операции.
    case add
}

struct ContentView: View {
    @State private var homeVM: HomeViewModel
    @State private var statisticsVM: StatisticsViewModel
    @State private var settingsVM: SettingsViewModel

    @State private var selectedTab: AppTab = .home
    @State private var addEntryVM: AddEntryViewModel?
    // Прокручен ли текущий экран ниже порога — тогда показываем сводку рядом со свёрнутым баром.
    @State private var isScrolled = false

    init(accountRepo: any AccountRepository,
         categoryRepo: any CategoryRepository,
         entryRepo: any EntryRepository) {
        _homeVM = State(wrappedValue: HomeViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo))
        _statisticsVM = State(wrappedValue: StatisticsViewModel(entryRepo: entryRepo))
        _settingsVM = State(wrappedValue: SettingsViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo))
    }

    var body: some View {
        // Нативный таб-бар iOS 26: настоящий Liquid Glass, перетаскивание пальцем по вкладкам,
        // сворачивание при скролле. Свой FloatingTabBar больше не используется.
        TabView(selection: tabSelection) {
            Tab(value: AppTab.home) {
                HomeView(viewModel: homeVM, selectedTab: $selectedTab, isScrolled: $isScrolled)
            } label: {
                tabLabel("Главная", icon: AppIcon.tabHome)
            }

            Tab(value: AppTab.statistics) {
                StatisticsView(viewModel: statisticsVM, isScrolled: $isScrolled)
            } label: {
                tabLabel("Статистика", icon: AppIcon.tabStatistics)
            }

            Tab(value: AppTab.accounts) {
                SettingsView(viewModel: settingsVM, isScrolled: $isScrolled)
            } label: {
                tabLabel("Счета", icon: AppIcon.tabAccounts)
            }

            // role: .search — система рисует вкладку отдельным круглым стеклом справа,
            // и при сворачивании бара он остаётся на месте. Используем это место под «+».
            Tab(value: AppTab.add, role: .search) {
                Color.clear
            } label: {
                tabLabel("Добавить", icon: AppIcon.add)
            }
        }
        .tint(Theme.Colors.accent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: isScrolled) {
            TabBarSummary(selectedTab: selectedTab, homeVM: homeVM)
        }
        .onChange(of: selectedTab) { isScrolled = false }
        .sheet(item: $addEntryVM, onDismiss: reloadAll) { vm in
            AddEntryView(viewModel: vm)
        }
    }

    /// Перехватывает тап по «+»: вкладка не переключается, открывается шит.
    private var tabSelection: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                if newValue == .add {
                    addEntryVM = homeVM.makeAddEntryViewModel()
                } else {
                    selectedTab = newValue
                }
            }
        )
    }

    private func tabLabel(_ title: String, icon: String) -> some View {
        Label {
            Text(title)
        } icon: {
            AppIcon.image(named: icon)
        }
    }

    private func reloadAll() {
        Task {
            await homeVM.load()
            await statisticsVM.load()
            await settingsVM.load()
        }
    }
}
