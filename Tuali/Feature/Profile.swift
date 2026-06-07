//
//  Profile.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct Profile: View {
    @State private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statsRow
                    businessSection
                    supportSection
                    signOutButton
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentMargins(.horizontal, 24, for: .scrollContent)
            .contentMargins(.vertical, 16, for: .scrollContent)
            .safeAreaInset(edge: .top) {
                AccentToolbar(
                    title: viewModel.store.name,
                    subtitle: "ID: \(viewModel.store.id) · \(viewModel.store.location)",
                    leading: {
                        storeIcon
                    },
                    belowContent: {
                        VStack(alignment: .leading, spacing: 16) {
                            membershipBadge
                            qrCard
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Toolbar pieces
    
    private var storeIcon: some View {
        Image(systemName: "storefront.fill")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.accent)
            .frame(width: 48, height: 48)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 12))
    }
    
    private var membershipBadge: some View {
        Text("Socio Arca Continental · Nivel \(viewModel.store.tier)")
            .font(.custom("Nexa-Heavy", size: 12, relativeTo: .caption))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white.opacity(0.18))
            .clipShape(Capsule())
    }
    
    private var qrCard: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Escanea tu código para sumar puntos")
                    .font(.custom("Nexa-Heavy", size: 15, relativeTo: .subheadline))
                    .multilineTextAlignment(.center)
                Text("Presenta este código en tus compras presenciales")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .foregroundStyle(.primary)
            
            Text("ID: \(viewModel.store.id) · Toca para ampliar")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
    
    // MARK: - Stats
    
    @ViewBuilder
    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(value: viewModel.stats.monthlySales, label: "Compras mes")
            statCard(value: viewModel.stats.points, label: "Puntos")
            statCard(value: viewModel.stats.orders, label: "Pedidos")
        }
    }
    
    @ViewBuilder
    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("Nexa-Heavy", size: 17, relativeTo: .headline))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var businessSection: some View {
        section(title: "MI NEGOCIO", rows: viewModel.businessRows)
    }
    
    @ViewBuilder
    private var supportSection: some View {
        section(title: "SOPORTE", rows: viewModel.supportRows)
    }
    
    @ViewBuilder
    private func section(title: String, rows: [ProfileRow]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("Nexa-Heavy", size: 12, relativeTo: .caption))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
            
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    settingsRow(row)
                    if index < rows.count - 1 {
                        Divider()
                            .padding(.leading, 62)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 16))
        }
    }
    
    @ViewBuilder
    private func settingsRow(_ row: ProfileRow) -> some View {
        Button {
            
        } label: {
            HStack(spacing: 14) {
                Image(systemName: row.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(row.tint)
                    .frame(width: 32, height: 32)
                    .background(row.tint.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title)
                        .font(.custom("Nexa-Heavy", size: 15, relativeTo: .subheadline))
                        .foregroundStyle(.primary)
                    if let subtitle = row.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Sign out
    
    @ViewBuilder
    private var signOutButton: some View {
        Button {
            
        } label: {
            Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                .font(.custom("Nexa-Heavy", size: 15, relativeTo: .headline))
                .foregroundStyle(.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}

// MARK: - Models

struct StoreInfo {
    let id: String
    let name: String
    let location: String
    let tier: String
}

struct ProfileStats {
    let monthlySales: String
    let points: String
    let orders: String
}

struct ProfileRow: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let tint: Color
}

@MainActor
@Observable
final class ProfileViewModel {
    let store = StoreInfo(
        id: "AC-MTY-004821",
        name: "Abarrotes El Trébol",
        location: "Monterrey, NL",
        tier: "Oro"
    )
    
    let stats = ProfileStats(
        monthlySales: "$48,200",
        points: "3,860",
        orders: "32"
    )
    
    let businessRows: [ProfileRow] = [
        ProfileRow(
            title: "Información de la tienda",
            subtitle: "Nombre, dirección, RFC",
            icon: "storefront.fill",
            tint: .accent
        ),
        ProfileRow(
            title: "Datos del propietario",
            subtitle: "Carlos Ramírez · Contacto",
            icon: "person.fill",
            tint: .accent
        ),
        ProfileRow(
            title: "Notificaciones",
            subtitle: "Pedidos, promos, alertas",
            icon: "bell.fill",
            tint: .blue
        ),
        ProfileRow(
            title: "Idioma y moneda",
            subtitle: "Español · MXN",
            icon: "globe",
            tint: .gray
        ),
        ProfileRow(
            title: "Seguridad y acceso",
            subtitle: "Contraseña · 2FA activo",
            icon: "lock.shield.fill",
            tint: .green
        )
    ]
    
    let supportRows: [ProfileRow] = [
        ProfileRow(
            title: "Centro de ayuda",
            subtitle: nil,
            icon: "questionmark.circle.fill",
            tint: .gray
        ),
        ProfileRow(
            title: "Soporte Arca Continental",
            subtitle: nil,
            icon: "headphones",
            tint: .gray
        )
    ]
}
