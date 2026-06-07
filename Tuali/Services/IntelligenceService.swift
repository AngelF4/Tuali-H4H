//
//  IntelligenceService.swift
//  Tuali
//
//  Created by Angel HG on 06/07/26.
//

import Foundation

actor IntelligenceService {
    static let shared = IntelligenceService()
    
    private let baseURL = URL(string: "http://45.32.195.31:8000")!
    private let session: URLSession = .shared
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func fetchResumen() async throws -> ResumenResponse {
        try await fetch("/api/v1/resumen")
    }
    
    func fetchMetas() async throws -> MetasResponse {
        try await fetch("/api/v1/metas")
    }
    
    private func fetch<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        print("🤖 [IntelligenceService] → GET \(url.absoluteString)")
        var request = URLRequest(url: url, timeoutInterval: 12)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("🤖 [IntelligenceService] ← \(status) \(path) (\(data.count) bytes)")
            
            guard (200..<300).contains(status) else {
                if let body = String(data: data, encoding: .utf8) {
                    print("❌ [IntelligenceService] non-2xx body: \(body.prefix(400))")
                }
                throw IntelligenceServiceError.httpStatus(status)
            }
            
            if let body = String(data: data, encoding: .utf8) {
                print("🤖 [IntelligenceService] body preview: \(body.prefix(400))")
            }
            
            let decoded = try decoder.decode(T.self, from: data)
            print("✅ [IntelligenceService] decoded \(T.self) from \(path)")
            return decoded
        } catch {
            print("❌ [IntelligenceService] error on \(path): \(error)")
            throw error
        }
    }
}

nonisolated enum IntelligenceServiceError: LocalizedError, Sendable {
    case httpStatus(Int)
    
    var errorDescription: String? {
        switch self {
            case .httpStatus(let status):
                "El servidor de IA respondió con el código HTTP \(status)."
        }
    }
}

// MARK: - Resumen

nonisolated struct ResumenResponse: Decodable, Sendable {
    let modulo: String
    let interpretacion: String
    let datos: ResumenDatos
}

nonisolated struct ResumenDatos: Decodable, Sendable {
    let ticketPromedio: Double
    let tasaEntregaPct: Double
    let ventaTotal: Double
    let totalPedidos: Int
    let productoMasCritico: String
    let tendenciaRecientePct: Double
    let notaTendencia: String
}

// MARK: - Metas

nonisolated struct MetasResponse: Decodable, Sendable {
    let modulo: String
    let interpretacion: String
    let datos: MetasDatos
}

nonisolated struct MetasDatos: Decodable, Sendable {
    let ticketActual: Double
    let tendenciaRecientePct: Double
    let notaTendencia: String
    let sugerencias: [MetaSugerencia]
}

nonisolated struct MetaSugerencia: Decodable, Identifiable, Sendable {
    var id: String { nivel }
    let nivel: String
    let ticketObjetivo: Double
    let incrementoPct: Double
    let descripcion: String
}
