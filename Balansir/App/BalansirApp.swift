import SwiftUI
import CoreData

@main
struct BalansirApp: App {
    private let persistence = PersistenceController.shared
    // Тема из Настроек (§4.8): меняется сразу, без перезапуска.
    @AppStorage(AppSettingsKey.appearance) private var appearance: AppearanceMode = .system

    var body: some Scene {
        WindowGroup {
            ContentView(
                accountRepo: CoreDataAccountRepository(context: persistence.container.viewContext),
                categoryRepo: CoreDataCategoryRepository(context: persistence.container.viewContext),
                entryRepo: CoreDataEntryRepository(context: persistence.container.viewContext)
            )
            .preferredColorScheme(appearance.colorScheme)
        }
    }
}
