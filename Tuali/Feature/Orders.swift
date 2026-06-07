//
//  Orders.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct Orders: View {
    @Environment(CartStore.self) private var cart
    @Environment(StoreDataStore.self) private var storeData
    @State private var viewModel = OrdersViewModel()
    @State private var multipeer = MultipeerManager.shared
    @State private var nearbyMessage: String?
    @State private var isShowingOrderQR = false
    @State private var selectedOrder: StoreTrackedOrder?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if cart.items.isEmpty {
                        emptyCartCard
                    } else {
                        cartSection
                    }
                    trackedOrdersSection
                    historySection
                    orderSharingSection
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
            .task {
                multipeer.startAdvertising()
                multipeer.startBrowsing()
                multipeer.onReceiveJSON = { data, _ in
                    if let response = try? JSONDecoder().decode(AgentOrderResponse.self, from: data) {
                        storeData.updateOrder(id: response.orderID, status: response.status, detail: response.detail)
                    } else if let report = try? JSONDecoder().decode(StoreVisitReportPayload.self, from: data) {
                        storeData.addReport(comment: report.comment, agentName: report.agentName)
                    }
                }
            }
            .alert("Envío por zona Bluetooth", isPresented: Binding(
                get: { nearbyMessage != nil },
                set: { if !$0 { nearbyMessage = nil } }
            )) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(nearbyMessage ?? "")
            }
            .sheet(isPresented: $isShowingOrderQR) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Código QR de tu pedido")
                            .font(.custom("Nexa-Heavy", size: 22, relativeTo: .title2))
                        QRCodeView(payload: selectedOrder?.qrPayload ?? "", size: 280)
                        Text(selectedOrder?.total.formatted(.currency(code: "MXN")) ?? "")
                            .foregroundStyle(.secondary)
                        Text(selectedOrder?.itemSummary ?? "")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        Text(selectedOrder?.statusDetail ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Cerrar") { isShowingOrderQR = false }
                        }
                    }
                }
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
    
    // MARK: - Order sharing
    
    @ViewBuilder
    private var orderSharingSection: some View {
        VStack(spacing: 12) {
            bluetoothShareCard
        }
    }
    
    private var trackedOrdersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proceso de pedidos")
                .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
            
            if storeData.orders.isEmpty {
                Text("Cuando hagas un pedido aparecerá aquí su seguimiento y código QR.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(storeData.orders) { order in
                    Button {
                        selectedOrder = order
                        isShowingOrderQR = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: order.status == .sent ? "paperplane.fill" : "checkmark.circle.fill")
                                .foregroundStyle(order.status == .sent ? .blue : .green)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(order.status.rawValue)
                                    .font(.headline)
                                Text(order.statusDetail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Text(order.total, format: .currency(code: "MXN"))
                                .font(.headline)
                        }
                        .padding(14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
    private var bluetoothShareCard: some View {
        Button {
            createAndSendOrder()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.blue)
                    .clipShape(.rect(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hacer pedido")
                        .font(.custom("Nexa-Heavy", size: 16, relativeTo: .headline))
                    Text("Enviar por Bluetooth y generar seguimiento QR")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 8)
                
                Image(systemName: "paperplane.fill")
                    .font(.footnote)
                    .foregroundStyle(.blue)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .disabled(cart.items.isEmpty)
        .opacity(cart.items.isEmpty ? 0.5 : 1)
    }
    
    private var bluetoothStatusText: String {
        let count = multipeer.connectedPeers.count
        if count > 0 {
            return "\(count) dispositivo\(count == 1 ? "" : "s") conectado\(count == 1 ? "" : "s")"
        }
        return "Buscando dispositivos Tuali cercanos…"
    }
    
    private func createAndSendOrder() {
        guard !cart.items.isEmpty else {
            nearbyMessage = "Agrega productos al pedido antes de enviarlo."
            return
        }
        
        let orderID = UUID()
        let total = cart.totalPrice
        let summary = cart.items.map { "\($0.quantity)x \($0.product.name)" }.joined(separator: ", ")
        let qrPayload = orderQRPayload(orderID: orderID)
        let payload = NearbyOrderPayload(
            id: orderID,
            sender: multipeer.localDisplayName,
            storeName: "Abarrotes El Trébol",
            zone: "Monterrey Centro",
            latitude: 25.6866,
            longitude: -100.3161,
            createdAt: .now,
            total: total,
            items: cart.items.map(NearbyOrderItem.init)
        )
        
        let wasSent = multipeer.sendJSON(payload)
        let trackedOrder = StoreTrackedOrder(
            id: orderID,
            createdAt: .now,
            total: total,
            itemSummary: summary,
            qrPayload: qrPayload,
            status: .sent,
            statusDetail: wasSent ? "Enviado al agente Arca cercano." : "Guardado. Se enviará cuando haya un agente conectado."
        )
        storeData.registerOrder(trackedOrder)
        selectedOrder = trackedOrder
        isShowingOrderQR = true
        cart.clear()
    }
    
    private func orderQRPayload(orderID: UUID) -> String {
        let products = cart.items
            .map { "\($0.product.sku):\($0.quantity)" }
            .joined(separator: ",")
        return "TUALI_ORDER|\(orderID.uuidString)|\(storeData.storeID)|\(products)|TOTAL:\(cart.totalPrice)"
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

struct NearbyOrderPayload: Codable, Sendable {
    let id: UUID
    let sender: String
    let storeName: String
    let zone: String
    let latitude: Double
    let longitude: Double
    let createdAt: Date
    let total: Double
    let items: [NearbyOrderItem]
}

struct NearbyOrderItem: Codable, Sendable {
    let name: String
    let sku: String
    let quantity: Int
    let unitsPerBox: Int
    let unitPrice: Double
    let subtotal: Double
    
    @MainActor
    init(_ item: CartItem) {
        name = item.product.name
        sku = item.product.sku
        quantity = item.quantity
        unitsPerBox = item.product.unitsPerBox
        unitPrice = item.product.price
        subtotal = item.subtotal
    }
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
