//
//  Rewards.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import SwiftUI

struct Rewards: View {
    @State private var viewModel = RewardsViewModel()
    @Environment(StoreDataStore.self) private var storeData
    
    private let darkCard = Color.accentColor
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    levelCard
                    tierSelector
                    monthlyChallenge
                    suggestedGoals
                    rewardsCatalog
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .task {
                await viewModel.loadIntelligence()
            }
            .contentMargins(.horizontal, 24, for: .scrollContent)
            .contentMargins(.vertical, 16, for: .scrollContent)
            .safeAreaInset(edge: .top) {
                AccentToolbar(
                    title: "Mis Recompensas",
                    trailing: {
                        Button {
                            
                        } label: {
                            Label("Historial", systemImage: "clock.arrow.circlepath")
                                .font(.custom("Nexa-Heavy", size: 12, relativeTo: .caption))
                                .padding(.horizontal, 4)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .tint(.white)
                    }
                )
            }
        }
    }
    
    // MARK: - Level Card
    
    @ViewBuilder
    private var levelCard: some View {
        let level = LevelStatus(
            name: storeData.points >= 5_000 ? "Nivel Diamante" : "Nivel Oro",
            nextName: storeData.points >= 5_000 ? "Máximo nivel" : "Diamante",
            totalPoints: storeData.points,
            nextThreshold: max(5_000, storeData.points)
        )
        
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "star.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.95, green: 0.75, blue: 0.30),
                                     Color(red: 0.80, green: 0.55, blue: 0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(.rect(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.name)
                        .font(.custom("Nexa-Heavy", size: 20, relativeTo: .title2))
                    Text("\(level.pointsToNext.formatted()) pts para \(level.nextName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 8)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(level.totalPoints.formatted())
                        .font(.custom("Nexa-Heavy", size: 26, relativeTo: .largeTitle))
                    Text("puntos totales")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(spacing: 8) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.accent.opacity(0.12))
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: proxy.size.width * level.progress)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(level.name): \(level.totalPoints.formatted())")
                        .font(.custom("Nexa-Heavy", size: 11, relativeTo: .caption2))
                        .foregroundStyle(.accent.opacity(0.6))
                    Spacer()
                    Text("\(level.nextName): \(level.nextThreshold.formatted())")
                        .font(.custom("Nexa-Heavy", size: 11, relativeTo: .caption2))
                        .foregroundStyle(.accent.opacity(0.6))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 24))
    }
    
    // MARK: - Tier Selector
    
    @ViewBuilder
    private var tierSelector: some View {
        HStack(spacing: 10) {
            ForEach(RewardTier.allCases, id: \.self) { tier in
                tierChip(tier: tier, isCurrent: viewModel.currentTier == tier)
            }
        }
    }
    
    @ViewBuilder
    private func tierChip(tier: RewardTier, isCurrent: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: tier.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isCurrent ? .white : tier.color)
            Text(tier.name)
                .font(.custom("Nexa-Heavy", size: 12, relativeTo: .caption))
                .foregroundStyle(isCurrent ? .white : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(isCurrent ? darkCard : Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
    
    // MARK: - Monthly Challenge
    
    @ViewBuilder
    private var monthlyChallenge: some View {
        let completed = min(storeData.completedOrders, 40)
        let challenge = MonthlyChallenge(
            title: "Completa 40 pedidos este mes",
            subtitle: "\(completed) de 40 pedidos completados",
            icon: "flame.fill",
            reward: 500,
            progress: Double(completed) / 40
        )
        
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Reto del mes")
                    .font(.custom("Nexa-Heavy", size: 17, relativeTo: .headline))
                Spacer()
                Text("Puntos x2")
                    .font(.custom("Nexa-Heavy", size: 12, relativeTo: .caption))
                    .foregroundStyle(.accent)
            }
            
            HStack(spacing: 12) {
                Image(systemName: challenge.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.accent)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(.rect(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.custom("Nexa-Heavy", size: 15, relativeTo: .subheadline))
                    Text(challenge.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("+\(challenge.reward) pts")
                    .font(.custom("Nexa-Heavy", size: 14, relativeTo: .subheadline))
                    .foregroundStyle(.accent)
            }
            
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: proxy.size.width * challenge.progress)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 18))
    }
    
    // MARK: - Suggested Goals
    
    @ViewBuilder
    private var suggestedGoals: some View {
        if viewModel.isLoadingMetas {
            suggestedGoalsLoading
        } else if let metas = viewModel.metas, !metas.datos.sugerencias.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text("Metas sugeridas")
                        .font(.custom("Nexa-Heavy", size: 17, relativeTo: .headline))
                    
                    Text("IA")
                        .font(.custom("Nexa-Heavy", size: 10, relativeTo: .caption2))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.indigo.gradient)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button {
                        Task { await viewModel.refreshIntelligence() }
                    } label: {
                        Label("Nuevas metas", systemImage: "arrow.clockwise")
                            .font(.custom("Nexa-Heavy", size: 12, relativeTo: .caption))
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .tint(.primary)
                }
                
                Text(metas.datos.notaTendencia)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ForEach(metas.datos.sugerencias.map(SuggestedGoal.init(from:))) { goal in
                    goalCard(goal: goal)
                }
            }
        } else if let errorMessage = viewModel.intelligenceError {
            intelligenceErrorCard(message: errorMessage)
        }
    }
    
    @ViewBuilder
    private func intelligenceErrorCard(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No se pudieron cargar las metas de IA")
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
        .padding(14)
        .background(Color.orange.opacity(0.1))
        .clipShape(.rect(cornerRadius: 16))
    }
    
    @ViewBuilder
    private var suggestedGoalsLoading: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text("Metas sugeridas")
                    .font(.custom("Nexa-Heavy", size: 17, relativeTo: .headline))
                
                Text("IA")
                    .font(.custom("Nexa-Heavy", size: 10, relativeTo: .caption2))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.indigo.gradient)
                    .clipShape(Capsule())
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                ProgressView()
                    .tint(.indigo)
                Text("Cargando las recomendaciones de la IA…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(.rect(cornerRadius: 16))
        }
    }
    
    @ViewBuilder
    private func goalCard(goal: SuggestedGoal) -> some View {
        let state: SuggestedGoal.State = storeData.acceptedGoalIDs.contains(goal.id) ? .inProgress : goal.state
        switch state {
            case .inProgress, .accepted:
                acceptedGoalCard(goal: goal)
            case .pending:
                pendingGoalCard(goal: goal)
        }
    }
    
    @ViewBuilder
    private func acceptedGoalCard(goal: SuggestedGoal) -> some View {
        HStack(spacing: 12) {
            Image(systemName: goal.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(goal.state == .accepted ? Color.green : Color.accentColor)
                .clipShape(.rect(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.custom("Nexa-Heavy", size: 14, relativeTo: .subheadline))
                Text("En proceso · \(min(storeData.points, goal.targetPoints).formatted()) de \(goal.targetPoints.formatted()) puntos")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ProgressView(value: Double(min(storeData.points, goal.targetPoints)), total: Double(goal.targetPoints))
                    .tint(.accent)
            }
            
            Spacer(minLength: 8)
            
            Text("+\(goal.reward) pts")
                .font(.custom("Nexa-Heavy", size: 13, relativeTo: .caption))
                .foregroundStyle(.accent)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func pendingGoalCard(goal: SuggestedGoal) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.accent)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(.rect(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.custom("Nexa-Heavy", size: 14, relativeTo: .subheadline))
                    Text(goal.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer(minLength: 8)
                
                Text("+\(goal.reward) pts")
                    .font(.custom("Nexa-Heavy", size: 13, relativeTo: .caption))
                    .foregroundStyle(.accent)
            }
            
            if let rationale = goal.rationale {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(rationale)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack(spacing: 10) {
                Button {
                    storeData.acceptGoal(goal.id)
                } label: {
                    Label("Aceptar meta", systemImage: "checkmark")
                        .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.regular)
                
                Button("Omitir") {
                    
                }
                .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
    
    // MARK: - Rewards Catalog
    
    @ViewBuilder
    private var rewardsCatalog: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Catálogo de premios")
                    .font(.custom("Nexa-Heavy", size: 17, relativeTo: .headline))
                Spacer()
                Button("Ver todo") {
                    
                }
                .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                .foregroundStyle(.accent)
            }
            
            featuredReward
            
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(viewModel.catalog) { reward in
                    rewardCell(reward: reward)
                }
            }
        }
    }
    
    @ViewBuilder
    private var featuredReward: some View {
        let featured = viewModel.featuredReward
        
        HStack(spacing: 14) {
            Image(systemName: featured.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.accentColor)
                .clipShape(.rect(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(featured.title)
                    .font(.custom("Nexa-Heavy", size: 15, relativeTo: .subheadline))
                    .foregroundStyle(.white)
                Text("\(featured.cost.formatted()) pts - Disponible ahora")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
            }
            
            Spacer(minLength: 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(darkCard)
        .clipShape(.rect(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func rewardCell(reward: CatalogReward) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: reward.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.accent)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(.rect(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.custom("Nexa-Heavy", size: 14, relativeTo: .subheadline))
                    .lineLimit(2, reservesSpace: true)
                Text("\(reward.cost.formatted()) pts")
                    .font(.custom("Nexa-Heavy", size: 13, relativeTo: .footnote))
                    .foregroundStyle(.accent)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}

// MARK: - Models

enum RewardTier: CaseIterable {
    case bronce
    case plata
    case oro
    case diamante
    
    var name: String {
        switch self {
            case .bronce: "Bronce"
            case .plata: "Plata"
            case .oro: "Oro"
            case .diamante: "Diamante"
        }
    }
    
    var icon: String {
        switch self {
            case .bronce, .plata, .oro: "trophy.fill"
            case .diamante: "diamond.fill"
        }
    }
    
    var color: Color {
        switch self {
            case .bronce: Color(red: 0.72, green: 0.45, blue: 0.20)
            case .plata: Color(red: 0.62, green: 0.62, blue: 0.65)
            case .oro: Color(red: 0.92, green: 0.68, blue: 0.20)
            case .diamante: Color(red: 0.45, green: 0.72, blue: 0.92)
        }
    }
}

struct LevelStatus {
    let name: String
    let nextName: String
    let totalPoints: Int
    let nextThreshold: Int
    
    var pointsToNext: Int { max(nextThreshold - totalPoints, 0) }
    var progress: Double {
        guard nextThreshold > 0 else { return 0 }
        return min(Double(totalPoints) / Double(nextThreshold), 1)
    }
}

struct MonthlyChallenge {
    let title: String
    let subtitle: String
    let icon: String
    let reward: Int
    let progress: Double
}

struct SuggestedGoal: Identifiable {
    enum State {
        case inProgress
        case accepted
        case pending
    }
    
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let reward: Int
    let targetPoints: Int
    let state: State
    let rationale: String?
}

extension SuggestedGoal {
    nonisolated init(from sugerencia: MetaSugerencia) {
        self.init(
            id: sugerencia.nivel,
            title: "Meta \(sugerencia.nivel.capitalized)",
            subtitle: "Ticket objetivo $\(Int(sugerencia.ticketObjetivo)) · +\(String(format: "%.1f", sugerencia.incrementoPct))%",
            icon: Self.icon(for: sugerencia.nivel),
            reward: Int(sugerencia.incrementoPct * 10),
            targetPoints: Int(sugerencia.ticketObjetivo),
            state: .pending,
            rationale: sugerencia.descripcion
        )
    }
    
    nonisolated private static func icon(for nivel: String) -> String {
        switch nivel.lowercased() {
            case "conservadora": "tortoise.fill"
            case "moderada": "hare.fill"
            case "agresiva": "flame.fill"
            default: "target"
        }
    }
}

struct CatalogReward: Identifiable {
    let id = UUID()
    let title: String
    let cost: Int
    let icon: String
}

@MainActor
@Observable
final class RewardsViewModel {
    let currentTier: RewardTier = .oro
    
    let level = LevelStatus(
        name: "Nivel Oro",
        nextName: "Diamante",
        totalPoints: 3_860,
        nextThreshold: 5_000
    )
    
    let monthlyChallenge = MonthlyChallenge(
        title: "Compra 5 días seguidos",
        subtitle: "3 de 5 días - Termina en 2 días",
        icon: "flame.fill",
        reward: 500,
        progress: 0.6
    )
    
    private(set) var metas: MetasResponse?
    private(set) var isLoadingMetas: Bool = false
    private(set) var intelligenceError: String?
    
    func loadIntelligence() async {
        guard metas == nil, !isLoadingMetas else { return }
        await fetchMetas()
    }
    
    func refreshIntelligence() async {
        guard !isLoadingMetas else { return }
        await fetchMetas()
    }
    
    private func fetchMetas() async {
        isLoadingMetas = true
        intelligenceError = nil
        print("🏆 [RewardsViewModel] requesting /api/v1/metas…")
        defer {
            isLoadingMetas = false
            print("🏆 [RewardsViewModel] finished requesting /api/v1/metas")
        }
        do {
            let response = try await IntelligenceService.shared.fetchMetas()
            print("🏆 [RewardsViewModel] metas OK · ticket actual: \(response.datos.ticketActual) · sugerencias: \(response.datos.sugerencias.map(\.nivel))")
            metas = response
        } catch {
            print("🏆 [RewardsViewModel] metas FAILED: \(error.localizedDescription)")
            metas = nil
            intelligenceError = error.localizedDescription
        }
    }
    
    let featuredReward = CatalogReward(
        title: "$200 de descuento en tu próximo pedido",
        cost: 5_000,
        icon: "gift.fill"
    )
    
    let catalog: [CatalogReward] = [
        CatalogReward(title: "Caja Coca-Cola gratis", cost: 1_500, icon: "shippingbox.fill"),
        CatalogReward(title: "Display Bokaditos gratis", cost: 1_200, icon: "bag.fill"),
        CatalogReward(title: "3 envíos gratis", cost: 800, icon: "shippingbox"),
        CatalogReward(title: "6-pack Topo Chico", cost: 600, icon: "waterbottle.fill")
    ]
}
