//
//  ContentView.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var cart = CartStore()
    @State private var storeData = StoreDataStore()
    @State private var permissions = AppPermissionManager()
    @State private var selectedRole: AppRole?
    
    var body: some View {
        Group {
            if let selectedRole {
                switch selectedRole {
                    case .store:
                        storeApp
                    case .agent:
                        AgentPortal(onSignOut: { self.selectedRole = nil })
                }
            } else {
                RoleLoginView(selectedRole: $selectedRole)
            }
        }
        .environment(cart)
        .environment(storeData)
        .overlay(alignment: .top) {
            if let productName = cart.lastAddedProductName {
                Label("\(productName) agregado al carrito", systemImage: "cart.fill.badge.plus")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.green.gradient)
                    .clipShape(Capsule())
                    .shadow(radius: 8)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring, value: cart.lastAddedProductName)
        .task {
            await permissions.requestAll()
        }
    }
    
    private var storeApp: some View {
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
    }
}

enum AppRole {
    case store
    case agent
}

struct RoleLoginView: View {
    @Binding var selectedRole: AppRole?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Image(.tualiLogo1)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                    Text("Bienvenido a Tuali")
                        .font(.custom("Nexa-Heavy", size: 30, relativeTo: .largeTitle))
                    Text("Selecciona el perfil con el que deseas ingresar.")
                        .foregroundStyle(.secondary)
                }
                
                roleButton(
                    title: "Sucursal",
                    subtitle: "Realiza pedidos, consulta recompensas y administra tu tienda",
                    icon: "storefront.fill",
                    role: .store
                )
                
                roleButton(
                    title: "Agente AC Digital",
                    subtitle: "Recibe pedidos cercanos, valida inventario y coordina entregas",
                    icon: "person.badge.shield.checkmark.fill",
                    role: .agent
                )
                
                Spacer()
            }
            .padding(24)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private func roleButton(title: String, subtitle: String, icon: String, role: AppRole) -> some View {
        Button {
            selectedRole = role
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.accentColor)
                    .clipShape(.rect(cornerRadius: 14))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.custom("Nexa-Heavy", size: 18, relativeTo: .headline))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
