//
//  Home.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct Home: View {
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    categorySection
                    
                    activePromotions
                    
                    productSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onScrollGeometryChange(for: Double.self) { geo in
                geo.contentOffset.y
            } action: { _, newValue in
                withAnimation {
                    viewModel.showSearch = newValue < 50
                }
            }
            .contentMargins(.horizontal, 24, for: .scrollContent)
            .contentMargins(.vertical, 8, for: .scrollContent)
            .safeAreaInset(edge: .top) {
                AccentToolbar(
                    kicker: "Buenos dias",
                    title: "Hola, María 👋",
                    subtitle: "Tienda La Esperanza",
                    trailing: {
                        NavigationLink {
                            Text("Notificaciones")
                        } label: {
                            Image(systemName: "bell")
                                .fontWeight(.medium)
                                .padding(4)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .tint(.white)
                    },
                    belowContent: {
                        if viewModel.showSearch {
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.tertiary)
                                TextField("Buscar Cocacola, Bokaditos, ...",
                                          text: $viewModel.searchText,
                                          axis: .horizontal)
                                .font(.headline)
                            }
                            .padding(.horizontal, 4)
                            .padding(8)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 8))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Categorías")
                    .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
                Spacer()
                Button("Ver todo") {
                    
                }
                .font(.custom("Nexa-Heavy", size: 15, relativeTo: .headline))
            }
            
            HStack(spacing: 24) {
                ForEach(CategorySection.allCases, id: \.self) { category in
                    HeaderCard(image: category.image,
                               isSelected: viewModel.selectedCateogry == category)
                    .onTapGesture {
                        viewModel.selectedCateogry = category
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var activePromotions: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Promociones activas")
                    .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
                Spacer()
                Button("Ver todo") {
                    
                }
                .font(.custom("Nexa-Heavy", size: 15, relativeTo: .headline))
            }
            
            HStack(spacing: 24) {
                ForEach(viewModel.activePromotions) { product in
                    ProductCard(product: product)
                        .containerRelativeFrame(.horizontal, count: 2, spacing: 24)
                }
            }
            
        }
    }
    
    @ViewBuilder
    private var productSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Productos")
                    .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
                Spacer()
            }
            
            
            AISuggestion(text: "Tus ventas de Coca-Cola han bajado un 5% este Trimestre, por lo que te recomendamos aprovechar esta promoción que tenemos para ti",
                         product: viewModel.suggestedProduct)
            
            ForEach(viewModel.products) { product in
                ProductCard(product: product)
            }
        }
    }
    
    @ViewBuilder
    private func HeaderCard(image: Image, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .colorScheme(isSelected ? .light : .dark)
        }
        .frame(height: 50)
        .foregroundStyle(isSelected ? .white : .primary)
        .padding(16)
        .containerRelativeFrame(.horizontal, count: 2, spacing: 24)
        .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 24))
        .overlay {
            if !isSelected {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.separator, lineWidth: 1)
            }
        }
        .contentShape(Rectangle())
        .animation(.spring, value: isSelected)
    }
    
    @ViewBuilder
    private func AISuggestion(text: String, product: Product) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Recomendación inteligente", systemImage: "sparkles")
                    .font(.custom("Nexa-Heavy", size: 13, relativeTo: .caption))
                    .foregroundStyle(.indigo.gradient)
                
                Text("Tus compras de \(product.name) bajaron un 5% este mes.")
                    .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
                    .foregroundStyle(.primary)
                
                Text("Aprovecha esta promoción para recuperar demanda y aumentar la rotación del producto.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ProductCard(product: product)
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                    .padding(.horizontal, 24)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(aiSuggestionGradient, lineWidth: 1.5)
                .blur(radius: 2)
                .opacity(0.6)
        }
        .shadow(color: .indigo.opacity(0.12), radius: 16, y: 8)
    }
    
    @ViewBuilder
    private func AISuggestionMetric(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.indigo)
                .frame(width: 32, height: 32)
                .background(.indigo.opacity(0.12))
                .clipShape(.rect(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Nexa-Heavy", size: 16, relativeTo: .headline))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground).opacity(0.75))
        .clipShape(.rect(cornerRadius: 14))
    }
    
    private var aiSuggestionGradient: AngularGradient {
        AngularGradient(
            colors: [.blue, .purple, .red, .orange, .yellow, .cyan, .blue],
            center: .center
        )
    }
    
}

#Preview {
    ContentView()
}

struct ProductCard: View {
    let product: Product
    
    var body: some View {
        NavigationLink {
            ProductDetail(product: product)
        } label: {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 16) {
                    Image(product.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                    
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name)
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                            Text("$ \(product.price, specifier: "%.2f")")
                                .font(.custom("Nexa-Heavy", size: 17, relativeTo: .title))
                        }
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(Circle())
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text(product.promotion)
                    .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                    .foregroundStyle(.white)
                    .padding(4)
                    .padding(.horizontal, 4)
                    .background(Color.accent)
                    .clipShape(.rect(cornerRadius: 4))
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }
}

struct Product: Identifiable {
    let id = UUID()
    
    let name: String
    let price: Double
    let imageName: String
    let sku: String
    let unitsPerBox: Int
    let summary: String
    
    let promotion = (PromotionType.allCases.randomElement() ?? .discount).rawValue
    
    var originalPrice: Double {
        switch promotion {
            case PromotionType.secondFree.rawValue: return price * 2
            case PromotionType.discount.rawValue: return price / (1 - 0.12)
            default: return price * 1.15
        }
    }
    
    static func randomMocks(count: Int) -> [Product] {
        (0..<count).compactMap { _ in
            guard let mock = mockCatalog.randomElement() else { return nil }
            
            return Product(
                name: mock.name,
                price: mock.price,
                imageName: mock.imageName,
                sku: mock.sku,
                unitsPerBox: mock.unitsPerBox,
                summary: mock.summary
            )
        }
    }
    
    static var randomMock: Product {
        randomMocks(count: 1).first ?? Product(
            name: "Paquete Coca-Cola Original 12 x 600 ml",
            price: 216,
            imageName: "cocaNormal",
            sku: "CC600",
            unitsPerBox: 12,
            summary: "Refresco de cola carbonatado. Botella PET retornable. Ideal para venta al detalle en tiendas de conveniencia."
        )
    }
    
    private static let mockCatalog: [(name: String, price: Double, imageName: String, sku: String, unitsPerBox: Int, summary: String)] = [
        ("Paquete Coca-Cola Original 12 x 600 ml", 216, "cocaNormal", "CC600", 12, "Refresco de cola carbonatado. Botella PET retornable. Ideal para venta al detalle en tiendas de conveniencia."),
        ("Paquete Coca-Cola Sin Azúcar 12 x 600 ml", 216, "cocaZero", "CCZ600", 12, "Refresco de cola sin azúcar y sin calorías. Botella PET retornable, lista para anaquel."),
        ("Paquete Fanta Naranja 12 x 600 ml", 204, "fanta", "FAN600", 12, "Refresco de naranja efervescente. Presentación familiar en botella PET de 600 ml."),
        ("Paquete Fresca Toronja 12 x 600 ml", 204, "sprite", "FRE600", 12, "Refresco de toronja con bajo aporte calórico. Ideal para clientes que buscan opciones ligeras."),
        ("Paquete Del Valle Néctar 12 x 413 ml", 192, "delValle", "DV413", 12, "Néctar de fruta natural sin colorantes artificiales. Presentación PET de 413 ml.")
    ]
}

enum PromotionType: String, CaseIterable {
    case secondFree = "2x1"
    case discount = "-12%"
}

@MainActor
@Observable
final class HomeViewModel {
    var searchText: String = ""
    var selectedCateogry: CategorySection = .coca
    var showSearch: Bool = true
    
    let activePromotions = Product.randomMocks(count: 2)
    let suggestedProduct = Product.randomMock
    let products = Product.randomMocks(count: 20)
}

enum CategorySection: Equatable, CaseIterable {
    case coca
    case bokados
    
    var image: Image {
        switch self {
            case .coca:
                Image(.coca)
            case .bokados:
                Image(.bokados)
        }
    }
    
}
