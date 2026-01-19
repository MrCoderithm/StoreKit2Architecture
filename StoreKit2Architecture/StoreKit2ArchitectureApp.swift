//
//  StoreKit2ArchitectureApp.swift
//  StoreKit2Architecture
//
//  Created by Ali Muhammad on 2026-01-18.
//

import SwiftUI

@main
struct StoreKit2ArchitectureApp: App {
    @State var store = StoreViewModel()
    
    var body: some Scene {
        WindowGroup {
            UnlocksListView(vm: UnlocksViewModel())
                .environmentObject(store)
        }
    }
}
