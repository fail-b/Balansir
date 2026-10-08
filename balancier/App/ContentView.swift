import SwiftUI

struct ContentView: View {
    @State private var homeVM: HomeViewModel
    @State private var transactionsVM: TransactionsViewModel
    @State private var statisticsVM: StatisticsViewModel
    @State private var settingsVM: SettingsViewModel

    init(accountRepo: any AccountRepository,
         categoryRepo: any CategoryRepository,
         entryRepo: any EntryRepository) {
        _homeVM = State(wrappedValue: HomeViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo))
        _transactionsVM = State(wrappedValue: TransactionsViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo))
        _statisticsVM = State(wrappedValue: StatisticsViewModel(entryRepo: entryRepo))
        _settingsVM = State(wrappedValue: SettingsViewModel(accountRepo: accountRepo, categoryRepo: categoryRepo, entryRepo: entryRepo))
    }

    var body: some View {
        TabView {
            HomeView(viewModel: homeVM)
                .tabItem { Label("Главная", systemImage: "house.fill") }

            TransactionsView(viewModel: transactionsVM)
                .tabItem { Label("Операции", systemImage: "list.bullet") }

            StatisticsView(viewModel: statisticsVM)
                .tabItem { Label("Статистика", systemImage: "chart.pie.fill") }

            SettingsView(viewModel: settingsVM)
                .tabItem { Label("Счета", systemImage: "creditcard.fill") }
        }
    }
}
