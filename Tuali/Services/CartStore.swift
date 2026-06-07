//
//  CartStore.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

@MainActor
@Observable
final class CartStore {
    private(set) var items: [CartItem] = []
    private(set) var lastAddedProductName: String?
    
    var totalCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    var totalPrice: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }
    
    func add(product: Product, quantity: Int) {
        guard quantity > 0 else { return }
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += quantity
        } else {
            items.append(CartItem(product: product, quantity: quantity))
        }
        lastAddedProductName = product.name
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            if lastAddedProductName == product.name {
                lastAddedProductName = nil
            }
        }
    }
    
    func remove(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func clear() {
        items.removeAll()
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    var product: Product
    var quantity: Int
    
    var subtotal: Double {
        product.price * Double(quantity)
    }
}
