//
//  Anchor_DownApp.swift
//  Anchor Down
//
//  Created by Alan Gutierrez Ramirez on 24/2/26.
//

import SwiftUI

@main
struct Anchor_DownApp: App {
    
    @StateObject var settings = SystemSettings()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(settings)
        }
    }
}
