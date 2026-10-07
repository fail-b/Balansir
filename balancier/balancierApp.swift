import SwiftUI
import CoreData

@main
struct balancierApp: App {
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                persistenceController.save()
            }
        }
    }
}
