import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Главная", systemImage: "house.fill") }

            TransactionsView()
                .tabItem { Label("Операции", systemImage: "list.bullet") }

            StatisticsView()
                .tabItem { Label("Статистика", systemImage: "chart.pie.fill") }

            SettingsView()
                .tabItem { Label("Счета", systemImage: "creditcard.fill") }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
