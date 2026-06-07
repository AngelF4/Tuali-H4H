//
//  ContentView.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Inicio", image: "home.fill") {
                Home()
            }
            Tab("Pedidos", systemImage: "cart") {
                
            }
            Tab("Recompensas", image: "apple.cash") {
                
            }
            Tab("Perfil", systemImage: "person") {
                
            }
        }
    }
}

#Preview {
    ContentView()
}
