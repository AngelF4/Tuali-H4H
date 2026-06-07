//
//  TualiApp.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

@main
struct TualiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    init() {
        setupAppearance()
    }
}

extension TualiApp {
    func setupAppearance() {
        setuTabBarAparrence()
    }
    private func setuTabBarAparrence() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        tabBarAppearance.backgroundColor = UIColor.secondarySystemGroupedBackground

        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.font: UIFont(name: "Nexa-Heavy", size: 13)!]
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.font: UIFont(name: "Nexa-Heavy", size: 12)!]
        
//        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = .white
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .gray
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
