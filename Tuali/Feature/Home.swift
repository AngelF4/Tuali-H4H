//
//  Home.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct Home: View {
    @State private var viewModel = HomeViewModel()
    @Environment(StoreDataStore.self) private var storeData
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    if !viewModel.searchText.isEmpty {
                        searchResultsSection
                    }
                    
                    categorySection
                    
                    activePromotions
                    
                    productSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .task {
                await viewModel.loadIntelligence()
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
                            StoreNotificationsView()
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
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resultados")
                .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
            
            if viewModel.searchResults.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else {
                ForEach(viewModel.searchResults) { product in
                    NavigationLink {
                        ProductDetail(product: product)
                    } label: {
                        HStack(spacing: 12) {
                            Image(product.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 58, height: 58)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(product.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(product.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Text(product.price, format: .currency(code: "MXN"))
                                .font(.headline)
                                .foregroundStyle(.accent)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
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
                    
                
            }
            
            HStack(spacing: 24) {
                ForEach(CategorySection.allCases, id: \.self) { category in
                    NavigationLink {
                        CategoryCatalogView(category: category)
                    } label: {
                        HeaderCard(image: category.image, isSelected: false)
                    }
                    .buttonStyle(.plain)
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
                NavigationLink("Ver todo") {
                    PromotionsCenterView()
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
                Text("Apoyo administrativo")
                    .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
                Spacer()
            }
            
            if viewModel.isLoadingResumen {
                AISuggestionLoading()
            } else if let resumen = viewModel.resumen {
                AISuggestion(resumen: resumen, product: viewModel.suggestedProduct)
            } else if let errorMessage = viewModel.intelligenceError {
                intelligenceErrorCard(message: errorMessage)
            }
            
            administrativeSupportCard
        }
    }
    
    private var administrativeSupportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Apoyo administrativo con IA", systemImage: "sparkles")
                .font(.custom("Nexa-Heavy", size: 16, relativeTo: .headline))
                .foregroundStyle(.indigo)
            Text("Llevas \(storeData.completedOrders) pedidos y \(storeData.monthlyPurchases.formatted(.currency(code: "MXN"))) en compras este mes.")
                .font(.subheadline)
            Text(storeData.monthlyPurchases >= 50_000
                 ? "Cumpliste tu meta mensual. Revisa las recompensas disponibles."
                 : "Sugerencia: agrega productos de alta rotación para acercarte a tu meta mensual de $50,000.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.indigo.opacity(0.1))
        .clipShape(.rect(cornerRadius: 20))
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
    private func AISuggestionLoading() -> some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(.indigo)
            VStack(alignment: .leading, spacing: 2) {
                Label("Recomendación inteligente", systemImage: "sparkles")
                    .font(.custom("Nexa-Heavy", size: 13, relativeTo: .caption))
                    .foregroundStyle(.indigo.gradient)
                Text("Cargando las recomendaciones de la IA…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
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
    private func intelligenceErrorCard(message: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No se pudo cargar la recomendación")
                    .font(.custom("Nexa-Heavy", size: 14, relativeTo: .subheadline))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
            
            Button("Reintentar") {
                Task { await viewModel.refreshIntelligence() }
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .clipShape(.rect(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func AISuggestion(resumen: ResumenResponse, product: Product) -> some View {
        let data = resumen.datos
        
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Recomendación inteligente", systemImage: "sparkles")
                    .font(.custom("Nexa-Heavy", size: 13, relativeTo: .caption))
                    .foregroundStyle(.indigo.gradient)
                
                Text("Producto más crítico: \(data.productoMasCritico)")
                    .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
                    .foregroundStyle(.primary)
                
                Text(data.notaTendencia)
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

struct CategoryCatalogView: View {
    let category: CategorySection
    
    @Environment(CartStore.self) private var cart
    @State private var quantities: [UUID: Int] = [:]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Product.catalog(for: category)) { product in
                    catalogRow(product)
                }
            }
            .padding(20)
        }
        .navigationTitle(category.title)
    }
    
    private func catalogRow(_ product: Product) -> some View {
        let quantity = quantities[product.id, default: 1]
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(product.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.name)
                        .font(.custom("Nexa-Heavy", size: 16, relativeTo: .headline))
                    Text(product.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(product.price, format: .currency(code: "MXN"))
                        .font(.custom("Nexa-Heavy", size: 18, relativeTo: .title3))
                        .foregroundStyle(.accent)
                }
            }
            
            HStack {
                Button {
                    quantities[product.id] = max(quantity - 1, 1)
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.bordered)
                
                Text("\(quantity) caja\(quantity == 1 ? "" : "s")")
                    .font(.headline)
                    .frame(minWidth: 80)
                
                Button {
                    quantities[product.id] = quantity + 1
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Agregar") {
                    cart.add(product: product, quantity: quantity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 20))
    }
}

struct StoreNotificationsView: View {
    @Environment(StoreDataStore.self) private var storeData
    
    var body: some View {
        List(storeData.notifications) { notification in
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: notification.icon)
                    .foregroundStyle(notification.tint)
                    .frame(width: 34, height: 34)
                    .background(notification.tint.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.title).font(.headline)
                    Text(notification.detail).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Notificaciones")
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
    
    static func randomMocks(count: Int, category: CategorySection = .coca) -> [Product] {
        (0..<count).compactMap { _ in
            guard let mock = catalog(for: category).randomElement() else { return nil }
            
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
        randomMock(category: .coca)
    }
    
    static func randomMock(category: CategorySection) -> Product {
        randomMocks(count: 1, category: category).first ?? Product(
            name: "Paquete Coca-Cola Original 12 x 600 ml",
            price: 216,
            imageName: "cocaNormal",
            sku: "CC600",
            unitsPerBox: 12,
            summary: "Refresco de cola carbonatado. Botella PET retornable. Ideal para venta al detalle en tiendas de conveniencia."
        )
    }
    
    static func catalog(for category: CategorySection) -> [Product] {
        switch category {
            case .coca: cocaProducts
            case .bokados: bokadosProducts
        }
    }
    
    private static func products(from catalog: [(name: String, price: Double, imageName: String, sku: String, unitsPerBox: Int, summary: String)]) -> [Product] {
        catalog.map { mock in
            Product(
                name: mock.name,
                price: mock.price,
                imageName: mock.imageName,
                sku: mock.sku,
                unitsPerBox: mock.unitsPerBox,
                summary: mock.summary
            )
        }
    }
    
    private static let cocaCatalog: [(name: String, price: Double, imageName: String, sku: String, unitsPerBox: Int, summary: String)] = [
        ("Paquete Coca-Cola Original 12 x 600 ml", 216, "cocaNormal", "CC600", 12, "Refresco de cola carbonatado. Botella PET retornable. Ideal para venta al detalle en tiendas de conveniencia."),
        ("Paquete Coca-Cola Sin Azúcar 12 x 600 ml", 216, "cocaZero", "CCZ600", 12, "Refresco de cola sin azúcar y sin calorías. Botella PET retornable, lista para anaquel."),
        ("Paquete Fanta Naranja 12 x 600 ml", 204, "fanta", "FAN600", 12, "Refresco de naranja efervescente. Presentación familiar en botella PET de 600 ml."),
        ("Paquete Fresca Toronja 12 x 600 ml", 204, "sprite", "FRE600", 12, "Refresco de toronja con bajo aporte calórico. Ideal para clientes que buscan opciones ligeras."),
        ("Paquete Del Valle Néctar 12 x 413 ml", 192, "delValle", "DV413", 12, "Néctar de fruta natural sin colorantes artificiales. Presentación PET de 413 ml.")
    ]
    
    private static let bokadosCatalog: [(name: String, price: Double, imageName: String, sku: String, unitsPerBox: Int, summary: String)] = [
        ("Caja Bokaditas 20 bolsas", 198, "bokaditas", "BOK-BKD", 20, "Crujientes frituras de maíz con sabor tradicional. Presentación individual ideal para venta al detalle."),
        ("Caja Prispas 20 bolsas", 210, "prispas", "BOK-PRS", 20, "Botana de maíz crujiente con sabor intenso. Caja lista para exhibición en tienda."),
        ("Caja Topitos 20 bolsas", 205, "topitos", "BOK-TOP", 20, "Totopos de maíz sazonados en presentación individual para consumo inmediato."),
        ("Caja Cacahuates Bokados 24 bolsas", 228, "cacahuates", "BOK-CAC", 24, "Cacahuates tostados y sazonados, empacados individualmente para conservar su frescura."),
        ("Caja Bokados Mix 18 bolsas", 234, "bokadosMix", "BOK-MIX", 18, "Surtido de botanas Bokados para ofrecer mayor variedad en el punto de venta."),
        ("Caja Strips 20 bolsas", 212, "strips", "BOK-STR", 20, "Tiras de maíz crujientes y sazonadas en prácticas bolsas individuales."),
        ("Caja Golos 20 bolsas", 208, "golos", "BOK-GOL", 20, "Botana de maíz con textura ligera y crujiente, ideal para anaquel."),
        ("Caja Enre2 20 bolsas", 214, "enre2", "BOK-ENR", 20, "Botana crujiente con forma divertida, lista para venta individual.")
    ]
    
    private static let cocaProducts = products(from: cocaCatalog)
    private static let bokadosProducts = products(from: bokadosCatalog)
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
    
    var activePromotions: [Product] {
        Array(Product.catalog(for: selectedCateogry).prefix(2))
    }
    
    var suggestedProduct: Product {
        Product.catalog(for: selectedCateogry).first ?? Product.randomMock
    }
    
    var products: [Product] {
        let categoryProducts = Product.catalog(for: selectedCateogry)
        guard !searchText.isEmpty else { return categoryProducts }
        
        return categoryProducts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var searchResults: [Product] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        
        let allProducts = CategorySection.allCases.flatMap(Product.catalog(for:))
        return allProducts
            .filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.summary.localizedCaseInsensitiveContains(query)
                    || $0.sku.localizedCaseInsensitiveContains(query)
            }
            .sorted {
                let leftStarts = $0.name.localizedCaseInsensitiveCompare(query) == .orderedSame
                    || $0.name.lowercased().hasPrefix(query.lowercased())
                let rightStarts = $1.name.localizedCaseInsensitiveCompare(query) == .orderedSame
                    || $1.name.lowercased().hasPrefix(query.lowercased())
                return leftStarts && !rightStarts
            }
    }
    
    private(set) var resumen: ResumenResponse?
    private(set) var isLoadingResumen: Bool = false
    private(set) var intelligenceError: String?
    
    func loadIntelligence() async {
        guard resumen == nil, !isLoadingResumen else { return }
        await refreshIntelligence()
    }
    
    func refreshIntelligence() async {
        guard !isLoadingResumen else { return }
        isLoadingResumen = true
        intelligenceError = nil
        print("🏠 [HomeViewModel] requesting /api/v1/resumen…")
        defer {
            isLoadingResumen = false
            print("🏠 [HomeViewModel] finished requesting /api/v1/resumen")
        }
        do {
            let response = try await IntelligenceService.shared.fetchResumen()
            print("🏠 [HomeViewModel] resumen OK · producto crítico: \(response.datos.productoMasCritico) · tendencia: \(response.datos.tendenciaRecientePct)%")
            resumen = response
        } catch {
            print("🏠 [HomeViewModel] resumen FAILED: \(error.localizedDescription)")
            resumen = nil
            intelligenceError = error.localizedDescription
        }
    }
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
    
    var title: String {
        switch self {
            case .coca: "Productos Coca-Cola"
            case .bokados: "Productos Bokados"
        }
    }
    
}
