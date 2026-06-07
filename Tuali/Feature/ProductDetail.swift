//
//  ProductDetail.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct ProductDetail: View {
    let product: Product
    
    @Environment(CartStore.self) private var cart
    @Environment(\.dismiss) private var dismiss
    
    @State private var quantity: Int = 1
    
    private var totalUnits: Int { quantity * product.unitsPerBox }
    private var totalPrice: Double { Double(quantity) * product.price }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroImage
                
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    promotionBanner
                    quantitySection
                    totalSection
                    descriptionSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(.systemBackground))
        .overlay(alignment: .topLeading) {
            backButton
                .padding(.horizontal, 20)
                .padding(.top, 8)
        }
        .safeAreaInset(edge: .bottom) {
            addToCartButton
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.background)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    // MARK: - Hero
    
    private var heroImage: some View {
        ZStack {
            Color.accentColor.opacity(0.18)
            Image(product.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .padding(.top, 32)
                .padding(.bottom, 16)
        }
        .frame(height: 320)
        .clipShape(.rect(bottomLeadingRadius: 28, bottomTrailingRadius: 28))
    }
    
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "arrow.left")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(Color(.systemBackground))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.custom("Nexa-Heavy", size: 22, relativeTo: .title2))
                    .foregroundStyle(.primary)
                Text("Caja × \(product.unitsPerBox) unidades · SKU-\(product.sku)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 8)
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(product.price, specifier: "%.2f")")
                    .font(.custom("Nexa-Heavy", size: 22, relativeTo: .title2))
                    .foregroundStyle(.accent)
                Text("$\(product.originalPrice, specifier: "%.2f")")
                    .font(.subheadline)
                    .strikethrough()
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Promotion banner
    
    private var promotionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "tag.fill")
                .font(.headline)
                .foregroundStyle(.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Promoción activa: \(product.promotion)")
                    .font(.custom("Nexa-Heavy", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(.accent)
                Text("Válido hasta el 30 de junio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.12))
        .clipShape(.rect(cornerRadius: 14))
    }
    
    // MARK: - Quantity
    
    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cantidad (cajas)")
                .font(.custom("Nexa-Heavy", size: 16, relativeTo: .headline))
            
            HStack(spacing: 16) {
                Button {
                    if quantity > 1 { quantity -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .frame(width: 48, height: 48)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.separator, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(quantity <= 1)
                
                Text("\(quantity)")
                    .font(.custom("Nexa-Heavy", size: 24, relativeTo: .title2))
                    .frame(minWidth: 32)
                
                Button {
                    quantity += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.accentColor)
                        .clipShape(.rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                
                Text("= \(totalUnits) unidades")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 0)
            }
        }
    }
    
    // MARK: - Total
    
    private var totalSection: some View {
        HStack {
            Text("Total del producto")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text("$\(totalPrice, specifier: "%.2f")")
                .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title3))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 12))
    }
    
    // MARK: - Description
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Descripción")
                .font(.custom("Nexa-Heavy", size: 16, relativeTo: .headline))
            Text(product.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Add to cart
    
    private var addToCartButton: some View {
        Button {
            cart.add(product: product, quantity: quantity)
            dismiss()
        } label: {
            Text("Agregar al carrito")
                .font(.custom("Nexa-Heavy", size: 17, relativeTo: .headline))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ProductDetail(product: .randomMock)
    }
    .environment(CartStore())
}
