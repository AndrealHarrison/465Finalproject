//
//  _65FinalprojectApp.swift
//  465Finalproject
//
//  Created by Andrea Harrison on 3/17/23.
//

import SwiftUI

@main
struct _65FinalprojectApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
