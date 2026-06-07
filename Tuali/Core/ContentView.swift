//
//  ContentView.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var cart = CartStore()
    
    var body: some View {
        TabView {
            Tab("Inicio", image: "home.fill") {
                Home()
            }
            Tab("Pedidos", systemImage: "cart") {
                Orders()
            }
            .badge(cart.totalCount)
            Tab("Recompensas", systemImage: "star") {
                Rewards()
            }
            Tab("Perfil", systemImage: "person") {
                Profile()
            }
        }
        .environment(cart)
    }
}

#Preview {
    ContentView()
}
