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
                VStack(alignment: .leading, spacing: 24) {
                    categorySection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentMargins(.horizontal, 24)
            .safeAreaInset(edge: .top) {
                toolbar
            }
        }
    }
    
    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Categorías")
                    .font(.custom("Nexa-Heavy", size: 24, relativeTo: .title2))
                Spacer()
                Button("Ver todo") {
                    
                }
                .font(.custom("Nexa-Heavy", size: 17, relativeTo: .headline))
            }
            
        }
    }
    
    @ViewBuilder
    private var toolbar: some View {
        VStack(spacing: 0) {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Buenos dias")
                            .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                            .foregroundStyle(.white.secondary)
                        Text("Hola, María 👋")
                            .font(.custom("Nexa-Heavy", size: 24, relativeTo: .title))
                            .foregroundStyle(.white)
                        Text("Tienda La Esperanza")
                            .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                            .foregroundStyle(.white.secondary)
                    }
                    Spacer()
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
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
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.accent)
            
        }
    }
}

#Preview {
    ContentView()
}

@MainActor
@Observable
final class HomeViewModel {
    var searchText: String = ""
    
    
}
