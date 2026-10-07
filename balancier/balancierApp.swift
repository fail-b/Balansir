//
//  balancierApp.swift
//  balancier
//
//  Created by failb on 07.10.2026.
//

import SwiftUI
import CoreData

@main
struct balancierApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
