//
//  Taya_Prototype_VictorApp.swift
//  Taya-Prototype-Victor
//
//  Created by Modi (Victor) Li.
//

import SwiftUI
import SwiftData

@main
struct Taya_Prototype_VictorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: MemoryItem.self)
    }
}
