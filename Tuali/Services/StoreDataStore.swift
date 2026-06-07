import SwiftUI
import CoreImage.CIFilterBuiltins
import UserNotifications

@MainActor
@Observable
final class StoreDataStore {
    let storeID = "AC-MTY-004821"
    let storeName = "Abarrotes El Trébol"
    let zone = "Monterrey Centro"
    
    private(set) var monthlyPurchases: Double = 48_200
    private(set) var points: Int = 3_860
    private(set) var completedOrders: Int = 32
    private(set) var notifications: [StoreNotification] = StoreNotification.mocks
    private(set) var monthlyReports: [StoreMonthlyReport] = StoreMonthlyReport.mocks
    private(set) var orders: [StoreTrackedOrder] = []
    private(set) var acceptedGoalIDs: Set<String> = []
    
    var profileQRPayload: String {
        "TUALI_PROFILE|\(storeID)|\(storeName)|\(zone)|\(monthlyPurchases)|\(points)|\(completedOrders)"
    }
    
    func registerOrder(_ order: StoreTrackedOrder) {
        guard !orders.contains(where: { $0.id == order.id }) else { return }
        orders.insert(order, at: 0)
        let total = order.total
        monthlyPurchases += total
        completedOrders += 1
        points += Int(total / 10)
        notifications.insert(
            StoreNotification(
                title: "Pedido enviado al agente Arca",
                detail: "Tu pedido por \(total.formatted(.currency(code: "MXN"))) está esperando confirmación.",
                icon: "paperplane.fill",
                tint: .blue
            ),
            at: 0
        )
        scheduleNotification(
            title: "Pedido enviado",
            body: "Tu pedido fue enviado al agente Arca y recibirás una respuesta cuando sea aceptado."
        )
        
        if monthlyPurchases >= 50_000 {
            notifications.insert(
                StoreNotification(
                    title: "Meta mensual cumplida",
                    detail: "Superaste $50,000 en compras y recibiste puntos adicionales.",
                    icon: "star.fill",
                    tint: .orange
                ),
                at: 0
            )
            scheduleNotification(
                title: "Meta mensual cumplida",
                body: "Superaste $50,000 en compras. Revisa tus nuevas recompensas."
            )
        }
    }
    
    func acceptGoal(_ id: String) {
        acceptedGoalIDs.insert(id)
    }
    
    func updateOrder(id: UUID, status: StoreOrderStatus, detail: String) {
        guard let index = orders.firstIndex(where: { $0.id == id }) else { return }
        orders[index].status = status
        orders[index].statusDetail = detail
        notifications.insert(
            StoreNotification(title: "Actualización de pedido", detail: detail, icon: "message.fill", tint: .green),
            at: 0
        )
    }
    
    func addReport(comment: String, agentName: String = "Mariana López") {
        monthlyReports.insert(
            StoreMonthlyReport(
                month: Date.now.formatted(.dateTime.month(.wide).year()),
                sales: monthlyPurchases,
                orders: completedOrders,
                agentComment: comment,
                agentName: agentName,
                signaturesCompleted: true
            ),
            at: 0
        )
    }
    
    private func scheduleNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}

enum StoreOrderStatus: String, Codable {
    case sent = "Enviado"
    case accepted = "Aceptado"
    case scheduled = "Entrega programada"
}

struct StoreTrackedOrder: Identifiable, Codable, Sendable {
    let id: UUID
    let createdAt: Date
    let total: Double
    let itemSummary: String
    let qrPayload: String
    var status: StoreOrderStatus
    var statusDetail: String
}

struct AgentOrderResponse: Codable, Sendable {
    let orderID: UUID
    let status: StoreOrderStatus
    let detail: String
}

struct StoreVisitReportPayload: Codable, Sendable {
    let comment: String
    let agentName: String
}

struct StoreNotification: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
    let tint: Color
    
    static let mocks = [
        StoreNotification(
            title: "Respuesta del agente Arca",
            detail: "Mariana confirmó inventario y propuso entrega mañana de 10:00 a 12:00.",
            icon: "message.fill",
            tint: .green
        ),
        StoreNotification(
            title: "Meta cerca de completarse",
            detail: "Te faltan $1,800 en compras para cumplir tu meta mensual.",
            icon: "target",
            tint: .orange
        )
    ]
}

struct StoreMonthlyReport: Identifiable {
    let id = UUID()
    let month: String
    let sales: Double
    let orders: Int
    let agentComment: String
    let agentName: String
    let signaturesCompleted: Bool
    
    static let mocks = [
        StoreMonthlyReport(
            month: "Mayo 2026",
            sales: 46_780,
            orders: 29,
            agentComment: "Buen nivel de exhibición. Se recomienda aumentar inventario de Coca-Cola Sin Azúcar y Bokados Mix.",
            agentName: "Mariana López",
            signaturesCompleted: true
        ),
        StoreMonthlyReport(
            month: "Abril 2026",
            sales: 43_120,
            orders: 27,
            agentComment: "Se actualizó material promocional y se acordó mejorar la rotación de botanas.",
            agentName: "Mariana López",
            signaturesCompleted: true
        )
    ]
}

struct QRCodeView: View {
    let payload: String
    var size: CGFloat = 220
    
    var body: some View {
        if let image = qrImage {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            ContentUnavailableView("No se pudo generar el QR", systemImage: "qrcode")
        }
    }
    
    private var qrImage: UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
