import SwiftUI
import UIKit

struct PromotionsCenterView: View {
    var body: some View {
        List {
            ForEach(PromotionGroup.allCases, id: \.self) { group in
                Section(group.title) {
                    ForEach(StorePromotion.mocks.filter { $0.group == group }) { promotion in
                        NavigationLink {
                            PromotionDetailView(promotion: promotion)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    ForEach(Array(promotion.products.prefix(2).enumerated()), id: \.element.id) { index, product in
                                        Image(product.imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 54, height: 54)
                                            .offset(x: CGFloat(index * 22))
                                    }
                                }
                                .frame(width: 80, height: 64)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(promotion.title).font(.headline)
                                    Text(promotion.subtitle).font(.caption).foregroundStyle(.secondary)
                                    Text(promotion.price, format: .currency(code: "MXN"))
                                        .font(.headline)
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Promociones")
    }
}

struct PromotionDetailView: View {
    let promotion: StorePromotion
    
    @Environment(CartStore.self) private var cart
    @State private var quantity = 1
    @State private var isShowingPoster = false
    
    var body: some View {
        List {
            Section {
                PromotionPosterView(promotion: promotion, palette: promotion.palette)
                    .frame(height: 300)
                    .listRowInsets(EdgeInsets())
            }
            
            Section("Incluye") {
                ForEach(promotion.products) { product in
                    NavigationLink {
                        ProductDetail(product: product)
                    } label: {
                        LabeledContent(product.name, value: product.price, format: .currency(code: "MXN"))
                    }
                }
            }
            
            Section("Cantidad de paquetes") {
                Stepper("\(quantity) paquete\(quantity == 1 ? "" : "s")", value: $quantity, in: 1...20)
                LabeledContent("Total", value: promotion.price * Double(quantity), format: .currency(code: "MXN"))
            }
            
            Section {
                Button {
                    for product in promotion.products {
                        cart.add(product: product, quantity: quantity)
                    }
                } label: {
                    Label("Agregar promoción al carrito", systemImage: "cart.badge.plus")
                }
                
                Button {
                    isShowingPoster = true
                } label: {
                    Label("Crear post para la sucursal", systemImage: "sparkles.rectangle.stack")
                }
            }
        }
        .navigationTitle(promotion.title)
        .sheet(isPresented: $isShowingPoster) {
            PromotionPosterCreator(promotion: promotion)
        }
    }
}

struct PromotionPosterCreator: View {
    let promotion: StorePromotion
    
    @Environment(\.dismiss) private var dismiss
    @State private var paletteIndex = 0
    @State private var posterURL: URL?
    
    private let palettes: [[Color]] = [
        [.red, .orange],
        [.blue, .cyan],
        [.purple, .pink],
        [.green, .mint]
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                PromotionPosterView(promotion: promotion, palette: palettes[paletteIndex])
                    .frame(height: 430)
                
                Button {
                    paletteIndex = (paletteIndex + 1) % palettes.count
                } label: {
                    Label("Generar variante visual", systemImage: "sparkles")
                }
                .buttonStyle(.bordered)
                
                HStack {
                    if let posterURL {
                        ShareLink(
                            item: posterURL,
                            subject: Text(promotion.title),
                            message: Text(promotion.subtitle),
                            preview: SharePreview(promotion.title)
                        ) {
                            Label("Compartir", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button {
                        guard let image = renderPoster() else { return }
                        let controller = UIPrintInteractionController.shared
                        controller.printingItem = image
                        controller.present(animated: true)
                    } label: {
                        Label("Imprimir", systemImage: "printer.fill")
                    }
                    .buttonStyle(.bordered)
                }
                
                Text("El creador está limitado al diseño visual de la promoción.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Crear post")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task(id: paletteIndex) {
                posterURL = createPosterFile()
            }
        }
    }
    
    @MainActor
    private func renderPoster() -> UIImage? {
        let renderer = ImageRenderer(
            content: PromotionPosterView(promotion: promotion, palette: palettes[paletteIndex])
                .frame(width: 800, height: 1000)
        )
        renderer.scale = 2
        return renderer.uiImage
    }
    
    @MainActor
    private func createPosterFile() -> URL? {
        guard let data = renderPoster()?.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("promocion-\(promotion.id)-\(paletteIndex).png")
        try? data.write(to: url, options: .atomic)
        return url
    }
}

struct PromotionPosterView: View {
    let promotion: StorePromotion
    let palette: [Color]
    
    var body: some View {
        ZStack {
            LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
            
            VStack(spacing: 16) {
                Text("PROMOCIÓN TUALI")
                    .font(.custom("Nexa-Heavy", size: 18, relativeTo: .headline))
                    .foregroundStyle(.white.opacity(0.85))
                Text(promotion.title)
                    .font(.custom("Nexa-Heavy", size: 30, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                HStack {
                    ForEach(promotion.products.prefix(3)) { product in
                        Image(product.imageName)
                            .resizable()
                            .scaledToFit()
                    }
                }
                .frame(height: 150)
                
                Text(promotion.price, format: .currency(code: "MXN"))
                    .font(.custom("Nexa-Heavy", size: 36, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
                Text(promotion.subtitle)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .clipShape(.rect(cornerRadius: 28))
    }
}

enum PromotionGroup: CaseIterable {
    case individual
    case sharing
    case family
    
    var title: String {
        switch self {
            case .individual: "Promociones de verano"
            case .sharing: "Promociones para compartir"
            case .family: "Promociones familiares"
        }
    }
}

struct StorePromotion: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let price: Double
    let group: PromotionGroup
    let products: [Product]
    let palette: [Color]
    
    static let mocks: [StorePromotion] = {
        let coca = Product.catalog(for: .coca)
        let bokados = Product.catalog(for: .bokados)
        return [
            StorePromotion(title: "Coca-Cola + Bokaditas", subtitle: "Combo individual para disfrutar", price: 350, group: .individual, products: [coca[0], bokados[0]], palette: [.red, .orange]),
            StorePromotion(title: "Fanta + Prispas", subtitle: "Sabor para tu tarde", price: 338, group: .individual, products: [coca[2], bokados[1]], palette: [.orange, .yellow]),
            StorePromotion(title: "Refrescos + Bokados Mix", subtitle: "Ideal para compartir", price: 650, group: .sharing, products: [coca[0], coca[1], bokados[4]], palette: [.blue, .purple]),
            StorePromotion(title: "Paquete familiar Tuali", subtitle: "Bebidas y botanas para toda la familia", price: 980, group: .family, products: [coca[0], coca[2], bokados[2], bokados[3]], palette: [.green, .blue])
        ]
    }()
}
