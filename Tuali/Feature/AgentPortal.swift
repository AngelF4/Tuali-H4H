import SwiftUI
import MapKit
import AVFoundation

struct AgentPortal: View {
    let onSignOut: () -> Void
    
    @State private var store = AgentOrderStore()
    @Environment(StoreDataStore.self) private var storeData
    
    var body: some View {
        TabView {
            Tab("Mensajes", systemImage: "message.fill") {
                AgentMessagesView(store: store)
            }
            .badge(store.pendingCount)
            
            Tab("Mapa", systemImage: "map.fill") {
                AgentMapView(orders: store.orders)
            }
            
            Tab("QR", systemImage: "qrcode.viewfinder") {
                NavigationStack {
                    AgentQRHub()
                }
            }
            
            Tab("Perfil", systemImage: "person.fill") {
                AgentProfileView(onSignOut: onSignOut)
            }
        }
        .task {
            store.startReceiving()
            store.importLocalOrders(storeData.orders)
        }
    }
}

struct AgentMessagesView: View {
    @Bindable var store: AgentOrderStore
    
    var body: some View {
        NavigationStack {
            List(store.orders) { order in
                NavigationLink {
                    AgentOrderDetail(order: order, store: store)
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(order.storeName)
                                .font(.custom("Nexa-Heavy", size: 16, relativeTo: .headline))
                            Spacer()
                            Text(order.status.title)
                                .font(.caption2.bold())
                                .foregroundStyle(order.status.color)
                        }
                        
                        Label(order.zone, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(order.items.count) productos · $\(order.total, specifier: "%.2f")")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 6)
                }
            }
            .overlay {
                if store.orders.isEmpty {
                    ContentUnavailableView(
                        "Sin pedidos cercanos",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("Los pedidos enviados por sucursales Tuali aparecerán aquí.")
                    )
                }
            }
            .navigationTitle("Mensajes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Label("Escuchando", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
    }
}

struct AgentOrderDetail: View {
    let order: AgentOrder
    @Bindable var store: AgentOrderStore
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreDataStore.self) private var storeData
    
    @State private var selectedSuggestion = 0
    @State private var confirmationMessage: String?
    
    private var currentOrder: AgentOrder {
        store.orders.first(where: { $0.id == order.id }) ?? order
    }
    
    var body: some View {
        List {
            Section("Sucursal") {
                LabeledContent("Nombre", value: currentOrder.storeName)
                LabeledContent("Zona", value: currentOrder.zone)
                LabeledContent("Total", value: currentOrder.total, format: .currency(code: "MXN"))
            }
            
            Section("Inventario solicitado") {
                ForEach(currentOrder.items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(.headline)
                            Text("\(item.quantity) caja\(item.quantity == 1 ? "" : "s") · SKU \(item.sku)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            store.toggleInventory(orderID: currentOrder.id, itemID: item.id)
                        } label: {
                            Label(
                                item.hasInventory ? "Disponible" : "Sin inventario",
                                systemImage: item.hasInventory ? "checkmark.circle.fill" : "xmark.circle.fill"
                            )
                            .font(.caption.bold())
                            .foregroundStyle(item.hasInventory ? .green : .red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Section("Horario sugerido por IA") {
                ForEach(Array(currentOrder.deliverySuggestions.enumerated()), id: \.offset) { index, suggestion in
                    Button {
                        selectedSuggestion = index
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(.headline)
                                Text(suggestion.message)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedSuggestion == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Section {
                Button {
                    let suggestion = currentOrder.deliverySuggestions[selectedSuggestion]
                    store.accept(orderID: currentOrder.id, suggestion: suggestion)
                    let response = AgentOrderResponse(
                        orderID: currentOrder.id,
                        status: .scheduled,
                        detail: suggestion.message
                    )
                    storeData.updateOrder(id: response.orderID, status: response.status, detail: response.detail)
                    MultipeerManager.shared.sendJSON(response)
                    confirmationMessage = suggestion.message
                } label: {
                    Label("Aceptar y coordinar entrega", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!currentOrder.allItemsAvailable)
            } footer: {
                if !currentOrder.allItemsAvailable {
                    Text("Marca todos los productos como disponibles antes de aceptar el pedido.")
                }
            }
        }
        .navigationTitle("Pedido recibido")
        .alert("Pedido aceptado", isPresented: Binding(
            get: { confirmationMessage != nil },
            set: { if !$0 { confirmationMessage = nil } }
        )) {
            Button("Continuar") {
                dismiss()
            }
        } message: {
            Text(confirmationMessage ?? "")
        }
    }
}

struct AgentMapView: View {
    let orders: [AgentOrder]
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.6866, longitude: -100.3161),
            span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.22)
        )
    )
    
    var body: some View {
        NavigationStack {
            Map(position: $position) {
                ForEach(orders) { order in
                    Marker(order.storeName, systemImage: "storefront.fill", coordinate: order.coordinate)
                        .tint(order.status.color)
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .navigationTitle("Mapa de entregas")
        }
    }
}

struct AgentProfileView: View {
    let onSignOut: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section("Agente") {
                    LabeledContent("Nombre", value: "Mariana López")
                    LabeledContent("Zona", value: "Monterrey Centro")
                    LabeledContent("Unidad", value: "AC-27")
                }
                
                Section {
                    Button("Cerrar sesión", role: .destructive, action: onSignOut)
                }
            }
            .navigationTitle("Agente AC Digital")
        }
    }
}

struct AgentQRHub: View {
    @State private var scanningType: AgentQRType?
    @State private var scannedResult: AgentQRType?
    
    var body: some View {
        List {
            Section {
                Text("Escanea el código generado por la sucursal para consultar su pedido o realizar una revisión completa.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section("Escanear código") {
                qrOption(
                    type: .order,
                    title: "QR de pedido e informe",
                    subtitle: "Consulta productos, cantidades, total e informe enviado",
                    icon: "shippingbox.fill"
                )
                qrOption(
                    type: .storeProfile,
                    title: "QR del perfil de sucursal",
                    subtitle: "Abre revisiones mensuales, reportes y acta de visita",
                    icon: "storefront.fill"
                )
            }
            
            Section("Prueba rápida") {
                Button("Abrir pedido de ejemplo") {
                    scannedResult = .order
                }
                Button("Abrir perfil de ejemplo") {
                    scannedResult = .storeProfile
                }
            }
        }
        .navigationTitle("Centro QR")
        .sheet(item: $scanningType) { type in
            NavigationStack {
                QRScannerView { _ in
                    scanningType = nil
                    scannedResult = type
                }
                .navigationTitle(type.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancelar") {
                            scanningType = nil
                        }
                    }
                }
            }
        }
        .navigationDestination(item: $scannedResult) { type in
            switch type {
                case .order:
                    ScannedOrderReportView()
                case .storeProfile:
                    StoreVisitReviewView()
            }
        }
    }
    
    private func qrOption(type: AgentQRType, title: String, subtitle: String, icon: String) -> some View {
        Button {
            scanningType = type
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.accentColor)
                    .clipShape(.rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

enum AgentQRType: String, Identifiable {
    case order
    case storeProfile
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
            case .order: "Escanear pedido"
            case .storeProfile: "Escanear perfil"
        }
    }
}

struct ScannedOrderReportView: View {
    private let order = AgentOrder.mockOrders[0]
    
    var body: some View {
        List {
            Section("Pedido recibido") {
                LabeledContent("Sucursal", value: order.storeName)
                LabeledContent("Zona", value: order.zone)
                LabeledContent("Folio", value: "PED-AC-10482")
                LabeledContent("Total", value: order.total, format: .currency(code: "MXN"))
            }
            
            Section("Productos") {
                ForEach(order.items) { item in
                    LabeledContent(item.name, value: "\(item.quantity) cajas")
                }
            }
            
            Section("Informe de la sucursal") {
                Text("Se solicita reposición prioritaria por alta rotación de bebidas y botanas durante el fin de semana.")
                Label("Inventario crítico reportado", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Label("Entrega preferida: mañana de 10:00 a 12:00", systemImage: "calendar")
            }
        }
        .navigationTitle("Pedido e informe")
    }
}

struct StoreVisitReviewView: View {
    @Environment(StoreDataStore.self) private var storeData
    @State private var comment = ""
    @State private var agentSignature: [[CGPoint]] = []
    @State private var storeSignature: [[CGPoint]] = []
    @State private var isCompleted = false
    
    var body: some View {
        List {
            Section("Perfil de sucursal") {
                LabeledContent("Sucursal", value: "Abarrotes El Trébol")
                LabeledContent("Responsable", value: "Carlos Ramírez")
                LabeledContent("Zona", value: "Monterrey Centro")
                LabeledContent("ID", value: "AC-MTY-004821")
            }
            
            Section("Revisión mensual") {
                reviewRow("Exhibición y anaqueles", status: "Correcto", color: .green)
                reviewRow("Inventario Coca-Cola", status: "Reponer", color: .orange)
                reviewRow("Inventario Bokados", status: "Correcto", color: .green)
                reviewRow("Material promocional", status: "Actualizar", color: .orange)
            }
            
            Section("Reportes") {
                LabeledContent("Ventas del mes", value: "$48,200")
                LabeledContent("Pedidos realizados", value: "32")
                LabeledContent("Entregas completas", value: "94%")
                LabeledContent("Incidencias abiertas", value: "1")
            }
            
            Section("Comentario del vendedor Arca") {
                TextField(
                    "Agrega observaciones, acuerdos y acciones siguientes",
                    text: $comment,
                    axis: .vertical
                )
                .lineLimit(4...8)
            }
            
            Section("Firma del agente Arca") {
                SignaturePad(strokes: $agentSignature)
            }
            
            Section("Firma del responsable de sucursal") {
                SignaturePad(strokes: $storeSignature)
            }
            
            Section {
                Button {
                    storeData.addReport(comment: comment)
                    MultipeerManager.shared.sendJSON(
                        StoreVisitReportPayload(comment: comment, agentName: "Mariana López")
                    )
                    isCompleted = true
                } label: {
                    Label("Finalizar revisión", systemImage: "checkmark.seal.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(comment.isEmpty || agentSignature.isEmpty || storeSignature.isEmpty)
            }
        }
        .navigationTitle("Revisión de sucursal")
        .alert("Revisión finalizada", isPresented: $isCompleted) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text("El comentario, los reportes y las firmas quedaron registrados.")
        }
    }
    
    private func reviewRow(_ title: String, status: String, color: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(status)
                .font(.caption.bold())
                .foregroundStyle(color)
        }
    }
}

struct SignaturePad: View {
    @Binding var strokes: [[CGPoint]]
    @State private var currentStroke: [CGPoint] = []
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Canvas { context, _ in
                for stroke in strokes + [currentStroke] {
                    guard let first = stroke.first else { continue }
                    var path = Path()
                    path.move(to: first)
                    for point in stroke.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(path, with: .color(.primary), lineWidth: 2)
                }
            }
            .frame(height: 140)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 12))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentStroke.append(value.location)
                    }
                    .onEnded { _ in
                        strokes.append(currentStroke)
                        currentStroke = []
                    }
            )
            
            Button("Limpiar firma") {
                strokes.removeAll()
                currentStroke.removeAll()
            }
            .font(.caption)
        }
    }
}

struct QRScannerView: View {
    let onScanned: (String) -> Void
    
    @State private var scanner = QRScannerController()
    
    var body: some View {
        ZStack {
            CameraPreview(session: scanner.session)
                .ignoresSafeArea()
            
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white, lineWidth: 3)
                .frame(width: 250, height: 250)
            
            VStack {
                Spacer()
                Text(scanner.statusMessage)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.black.opacity(0.65))
                    .clipShape(Capsule())
                    .padding(.bottom, 40)
            }
        }
        .task {
            scanner.onScanned = onScanned
            await scanner.start()
        }
        .onDisappear {
            scanner.stop()
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

@MainActor
@Observable
final class QRScannerController: NSObject {
    let session = AVCaptureSession()
    var statusMessage = "Coloca el código QR dentro del recuadro"
    var onScanned: ((String) -> Void)?
    
    private let metadataOutput = AVCaptureMetadataOutput()
    private var isConfigured = false
    private var hasScanned = false
    
    func start() async {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let isAuthorized: Bool
        
        if authorizationStatus == .notDetermined {
            isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        } else {
            isAuthorized = authorizationStatus == .authorized
        }
        
        guard isAuthorized else {
            statusMessage = "Autoriza el acceso a la cámara para escanear pedidos"
            return
        }
        
        guard configureSession() else { return }
        Task.detached { [session] in
            session.startRunning()
        }
    }
    
    func stop() {
        guard session.isRunning else { return }
        Task.detached { [session] in
            session.stopRunning()
        }
    }
    
    private func configureSession() -> Bool {
        guard !isConfigured else { return true }
        guard let camera = AVCaptureDevice.default(for: .video) else {
            statusMessage = "Este dispositivo no tiene una cámara disponible"
            return false
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            guard session.canAddInput(input), session.canAddOutput(metadataOutput) else {
                statusMessage = "No fue posible iniciar el escáner"
                return false
            }
            
            session.beginConfiguration()
            session.addInput(input)
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [.qr]
            session.commitConfiguration()
            isConfigured = true
            return true
        } catch {
            statusMessage = "No fue posible acceder a la cámara"
            return false
        }
    }
}

extension QRScannerController: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        
        Task { @MainActor [weak self] in
            guard let self, !hasScanned else { return }
            hasScanned = true
            stop()
            onScanned?(value)
        }
    }
}

enum AgentOrderStatus {
    case pending
    case accepted
    
    var title: String {
        switch self {
            case .pending: "Pendiente"
            case .accepted: "Aceptado"
        }
    }
    
    var color: Color {
        switch self {
            case .pending: .orange
            case .accepted: .green
        }
    }
}

struct DeliverySuggestion {
    let title: String
    let message: String
}

struct AgentOrderItem: Identifiable {
    let id = UUID()
    let name: String
    let sku: String
    let quantity: Int
    var hasInventory: Bool
}

struct AgentOrder: Identifiable {
    let id: UUID
    let storeName: String
    let zone: String
    let latitude: Double
    let longitude: Double
    let total: Double
    var items: [AgentOrderItem]
    var status: AgentOrderStatus
    let deliverySuggestions: [DeliverySuggestion]
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var allItemsAvailable: Bool {
        items.allSatisfy(\.hasInventory)
    }
}

@MainActor
@Observable
final class AgentOrderStore {
    private(set) var orders: [AgentOrder] = AgentOrder.mockOrders
    private let multipeer = MultipeerManager.shared
    
    var pendingCount: Int {
        orders.filter { $0.status == .pending }.count
    }
    
    func startReceiving() {
        multipeer.startAdvertising()
        multipeer.startBrowsing()
        multipeer.onReceiveJSON = { [weak self] data, _ in
            guard let payload = try? JSONDecoder().decode(NearbyOrderPayload.self, from: data) else { return }
            self?.add(payload)
        }
    }
    
    func importLocalOrders(_ localOrders: [StoreTrackedOrder]) {
        for order in localOrders where !orders.contains(where: { $0.id == order.id }) {
            let items = order.itemSummary
                .split(separator: ",")
                .map {
                    AgentOrderItem(name: String($0).trimmingCharacters(in: .whitespaces), sku: "LOCAL", quantity: 1, hasInventory: true)
                }
            orders.insert(
                AgentOrder(
                    id: order.id,
                    storeName: "Abarrotes El Trébol",
                    zone: "Monterrey Centro",
                    latitude: 25.6866,
                    longitude: -100.3161,
                    total: order.total,
                    items: items,
                    status: order.status == .sent ? .pending : .accepted,
                    deliverySuggestions: AgentOrder.defaultSuggestions
                ),
                at: 0
            )
        }
    }
    
    func toggleInventory(orderID: UUID, itemID: UUID) {
        guard let orderIndex = orders.firstIndex(where: { $0.id == orderID }),
              let itemIndex = orders[orderIndex].items.firstIndex(where: { $0.id == itemID }) else { return }
        orders[orderIndex].items[itemIndex].hasInventory.toggle()
    }
    
    func accept(orderID: UUID, suggestion: DeliverySuggestion) {
        guard let index = orders.firstIndex(where: { $0.id == orderID }),
              orders[index].allItemsAvailable else { return }
        orders[index].status = .accepted
    }
    
    private func add(_ payload: NearbyOrderPayload) {
        orders.insert(
            AgentOrder(
                id: payload.id,
                storeName: payload.storeName,
                zone: payload.zone,
                latitude: payload.latitude,
                longitude: payload.longitude,
                total: payload.total,
                items: payload.items.map {
                    AgentOrderItem(name: $0.name, sku: $0.sku, quantity: $0.quantity, hasInventory: true)
                },
                status: .pending,
                deliverySuggestions: AgentOrder.defaultSuggestions
            ),
            at: 0
        )
    }
}

extension AgentOrder {
    static let defaultSuggestions = [
        DeliverySuggestion(
            title: "Mañana · 10:00 a 12:00",
            message: "Hola, tenemos inventario completo. Podemos entregar tu pedido mañana entre 10:00 y 12:00."
        ),
        DeliverySuggestion(
            title: "Mañana · 15:00 a 17:00",
            message: "Tu pedido está disponible. Sugerimos programar la entrega mañana entre 15:00 y 17:00."
        ),
        DeliverySuggestion(
            title: "Próximo día hábil · 09:00 a 11:00",
            message: "Confirmamos existencia de todos los productos. Podemos entregar el próximo día hábil entre 09:00 y 11:00."
        )
    ]
    
    static let mockOrders = [
        AgentOrder(
            id: UUID(),
            storeName: "Abarrotes El Trébol",
            zone: "Monterrey Centro",
            latitude: 25.6866,
            longitude: -100.3161,
            total: 1_248,
            items: [
                AgentOrderItem(name: "Paquete Coca-Cola Original", sku: "CC600", quantity: 3, hasInventory: true),
                AgentOrderItem(name: "Caja Bokaditas", sku: "BOK-BKD", quantity: 2, hasInventory: true)
            ],
            status: .pending,
            deliverySuggestions: defaultSuggestions
        ),
        AgentOrder(
            id: UUID(),
            storeName: "Tienda La Esperanza",
            zone: "San Nicolás",
            latitude: 25.7417,
            longitude: -100.3028,
            total: 860,
            items: [
                AgentOrderItem(name: "Caja Prispas", sku: "BOK-PRS", quantity: 4, hasInventory: false)
            ],
            status: .pending,
            deliverySuggestions: defaultSuggestions
        ),
        AgentOrder(
            id: UUID(),
            storeName: "Mini Súper Las Torres",
            zone: "Guadalupe",
            latitude: 25.6774,
            longitude: -100.2594,
            total: 1_530,
            items: [
                AgentOrderItem(name: "Paquete Coca-Cola Sin Azúcar", sku: "CCZ600", quantity: 5, hasInventory: true),
                AgentOrderItem(name: "Caja Topitos", sku: "BOK-TOP", quantity: 2, hasInventory: true)
            ],
            status: .accepted,
            deliverySuggestions: defaultSuggestions
        ),
        AgentOrder(
            id: UUID(),
            storeName: "Abarrotes San Jorge",
            zone: "Santa Catarina",
            latitude: 25.6732,
            longitude: -100.4581,
            total: 720,
            items: [
                AgentOrderItem(name: "Caja Cacahuates Bokados", sku: "BOK-CAC", quantity: 3, hasInventory: true)
            ],
            status: .pending,
            deliverySuggestions: defaultSuggestions
        ),
        AgentOrder(
            id: UUID(),
            storeName: "Mercadito del Valle",
            zone: "Apodaca",
            latitude: 25.7816,
            longitude: -100.1887,
            total: 2_140,
            items: [
                AgentOrderItem(name: "Paquete Fanta Naranja", sku: "FAN600", quantity: 4, hasInventory: true),
                AgentOrderItem(name: "Caja Bokados Mix", sku: "BOK-MIX", quantity: 5, hasInventory: true)
            ],
            status: .accepted,
            deliverySuggestions: defaultSuggestions
        )
    ]
}
