//
//  Orders.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct Orders: View {
    @Environment(CartStore.self) private var cart
    @State private var viewModel = OrdersViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if cart.items.isEmpty {
                        emptyCartCard
                    } else {
                        cartSection
                    }
                    historySection
                    qrSyncCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentMargins(.horizontal, 24, for: .scrollContent)
            .contentMargins(.vertical, 16, for: .scrollContent)
            .safeAreaInset(edge: .top) {
                AccentToolbar(
                    title: "Mis Pedidos",
                    subtitle: "Seguimiento y gestión de compras"
                )
            }
        }
    }
    
    // MARK: - Cart
    
    @ViewBuilder
    private var cartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("EN PREPARACIÓN")
                    .font(.custom("Nexa-Heavy", size: 11, relativeTo: .caption))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accent)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text("\(cart.totalCount) producto\(cart.totalCount == 1 ? "" : "s")")
                    .font(.custom("Nexa-Heavy", size: 12, relativeTo: .caption))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mi pedido")
                    .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
                Text("Productos seleccionados para tu próximo pedido")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 10) {
                ForEach(cart.items) { item in
                    cartRow(item: item)
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.custom("Nexa-Heavy", size: 16, relativeTo: .headline))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("$\(cart.totalPrice, specifier: "%.2f")")
                    .font(.custom("Nexa-Heavy", size: 22, relativeTo: .title2))
                    .foregroundStyle(.accent)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 24))
    }
    
    @ViewBuilder
    private func cartRow(item: CartItem) -> some View {
        HStack(spacing: 12) {
            Image(item.product.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(.rect(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.custom("Nexa-Heavy", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text("\(item.quantity) caja\(item.quantity == 1 ? "" : "s") · $\(item.subtotal, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 8)
            
            Button {
                cart.remove(item)
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(.accent)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
    
    @ViewBuilder
    private var emptyCartCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "cart")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Tu carrito está vacío")
                .font(.custom("Nexa-Heavy", size: 16, relativeTo: .headline))
            Text("Agrega productos desde la pantalla de inicio para verlos aquí.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 24))
    }
    
    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Historial")
                    .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
                Spacer()
                Button("Ver todos") {
                    
                }
                .font(.custom("Nexa-Heavy", size: 14, relativeTo: .subheadline))
                .foregroundStyle(.accent)
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.history) { order in
                    historyRow(order: order)
                }
            }
        }
    }
    
    @ViewBuilder
    private func historyRow(order: PastOrder) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(order.title)
                    .font(.custom("Nexa-Heavy", size: 15, relativeTo: .headline))
                    .foregroundStyle(.primary)
                Text(order.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(order.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 12)
            
            VStack(alignment: .trailing, spacing: 6) {
                Text("$\(Int(order.total))")
                    .font(.custom("Nexa-Heavy", size: 18, relativeTo: .title3))
                Button("Reordenar") {
                    
                }
                .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                .foregroundStyle(.accent)
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var qrSyncCard: some View {
        Button {
            
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "qrcode")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.accentColor)
                    .clipShape(.rect(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sincronizar con QR")
                        .font(.custom("Nexa-Heavy", size: 16, relativeTo: .headline))
                    Text("Confirmar entrega en punto de venta")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 8)
                
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}

// MARK: - Models

struct PastOrder: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let description: String
    let total: Double
}

@MainActor
@Observable
final class OrdersViewModel {
    let history: [PastOrder] = [
        PastOrder(
            title: "Pedido Coca-Cola + Bokaditos",
            date: "Jun 14, 2025",
            description: "8 productos - Sprite, Fanta, Bocachitos",
            total: 3450
        ),
        PastOrder(
            title: "Reposición Topo Chico + Ades",
            date: "Jun 10, 2025",
            description: "4 productos",
            total: 980
        ),
        PastOrder(
            title: "Pedido Bokaditos surtido",
            date: "Jun 06, 2025",
            description: "Topitos, Prispas, Ruedas, Golos",
            total: 540
        )
    ]
}
