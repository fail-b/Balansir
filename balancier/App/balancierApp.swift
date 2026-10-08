import SwiftUI
import CoreData

@main
struct balancierApp: App {
    private let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(
                accountRepo: CoreDataAccountRepository(context: persistence.container.viewContext),
                categoryRepo: CoreDataCategoryRepository(context: persistence.container.viewContext),
                entryRepo: CoreDataEntryRepository(context: persistence.container.viewContext)
            )
        }
    }
}
