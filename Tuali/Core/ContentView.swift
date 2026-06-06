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
            Tab("Asistente Virtual",
                image: "tray.fill.badge.sparkles") {
                
            }
            Tab("Carrito", systemImage: "cart") {
                
            }
            Tab("Perfil", systemImage: "person") {
                
            }
        }
    }
}

#Preview {
    ContentView()
}
