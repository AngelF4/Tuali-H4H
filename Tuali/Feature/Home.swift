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
                    RoundedRectangle(cornerRadius: 16)
                        .frame(height: 200)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentMargins(24)
            .safeAreaInset(edge: .top) {
                toolbar
            }
        }
    }
    
    @ViewBuilder
    private var toolbar: some View {
        VStack(spacing: 0) {
            HStack {
                //Selector de tienda
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sucursal")
                        .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                        .foregroundStyle(.secondary)
                    Menu {
                        ForEach(StoreMock.allCases, id: \.self) { store in
                            Button {
                                viewModel.storeSelection = store
                            } label: {
                                HStack {
                                    if store == viewModel.storeSelection {
                                        Image(systemName: "checkmark")
                                    }
                                    Text(store.name)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(viewModel.storeSelection.name)
                                .contentTransition(.numericText())
                                .font(.custom("Nexa-Heavy", size: 17, relativeTo: .footnote))
                            Image(systemName: "chevron.down")
                                .font(.subheadline)
                        }
                        .animation(.default, value: viewModel.storeSelection)
                    }
                }
                Spacer()
                //botones de navegación
                NavigationLink {
                    Text("Perfil")
                } label: {
                    Image(systemName: "gear")
                        .font(.title2)
                }
                
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.separator)
        }
    }
}

enum StoreMock: Equatable, CaseIterable {
    case store1
    case store2
    
    var name: String {
        switch self {
            case .store1:
                "Tienda San José"
            case .store2:
                "Tienda Pedro de Dante"
        }
    }
}

#Preview {
    ContentView()
}

@MainActor
@Observable
final class HomeViewModel {
    var storeSelection: StoreMock = .store1
    
    
}
