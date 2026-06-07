//
//  MultipeerManager.swift
//  Tuali
//
//  Created by Angel HG on 06/06/26.
//

import Foundation
import MultipeerConnectivity
import Observation
import UIKit

// MARK: - Constantes del servicio

/// Identificador del servicio Multipeer. Debe tener entre 1 y 15 caracteres,
/// solo letras minúsculas, dígitos y guiones. Debe coincidir con la entrada
/// `NSBonjourServices` del Info.plist.
private let kTualiServiceType = "tuali-mpc"

// MARK: - Estado de un peer

/// Estado simplificado de un peer dentro de la sesión.
enum PeerConnectionState {
    case notConnected
    case connecting
    case connected
}

// MARK: - Singleton

@Observable
final class MultipeerManager: NSObject {
    
    /// Instancia única compartida.
    static let shared = MultipeerManager()
    
    // MARK: Estado expuesto (solo lectura desde fuera)
    
    /// Peers actualmente conectados a la sesión.
    private(set) var connectedPeers: [MCPeerID] = []
    
    /// Peers encontrados durante el browsing (todavía no conectados).
    private(set) var discoveredPeers: [MCPeerID] = []
    
    /// Indica si actualmente la app está anunciándose como anfitrión.
    private(set) var isAdvertising: Bool = false
    
    /// Indica si actualmente la app está buscando peers cercanos.
    private(set) var isBrowsing: Bool = false
    
    /// Último payload JSON recibido (datos crudos).
    private(set) var lastReceivedJSON: Data?
    
    /// Peer del que provino el último JSON recibido.
    private(set) var lastReceivedFromPeer: MCPeerID?
    
    /// Invitación pendiente por aceptar o rechazar, si existe.
    private(set) var pendingInvitationPeer: MCPeerID?
    
    /// Si está activo, las invitaciones entrantes se aceptan automáticamente.
    var automaticallyAcceptInvitations: Bool = true
    
    // MARK: Callbacks para el ViewModel
    
    /// Se invoca cuando se recibe un payload JSON desde un peer.
    var onReceiveJSON: ((Data, MCPeerID) -> Void)?
    
    /// Se invoca cuando un peer envía una invitación. Use `accept(_:)` para responder.
    var onInvitationReceived: ((MCPeerID) -> Void)?
    
    /// Se invoca cuando cambia el estado de conexión de un peer.
    var onPeerStateChange: ((MCPeerID, PeerConnectionState) -> Void)?
    
    /// Se invoca cuando se descubre un peer nuevo durante el browsing.
    var onPeerDiscovered: ((MCPeerID) -> Void)?
    
    /// Se invoca cuando se pierde un peer previamente descubierto.
    var onPeerLost: ((MCPeerID) -> Void)?
    
    // MARK: Propiedades internas (no observables)
    
    @ObservationIgnored private let myPeerID: MCPeerID
    @ObservationIgnored private let session: MCSession
    @ObservationIgnored private let advertiser: MCNearbyServiceAdvertiser
    @ObservationIgnored private let browser: MCNearbyServiceBrowser
    @ObservationIgnored private var pendingInvitationHandler: ((Bool, MCSession?) -> Void)?
    
    /// Nombre con el que este dispositivo es visible para otros peers.
    var localDisplayName: String { myPeerID.displayName }
    
    // MARK: - Init
    
    private override init() {
        let displayName = UIDevice.current.name
        let peerID = MCPeerID(displayName: displayName)
        self.myPeerID = peerID
        self.session = MCSession(
            peer: peerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: nil,
            serviceType: kTualiServiceType
        )
        self.browser = MCNearbyServiceBrowser(
            peer: peerID,
            serviceType: kTualiServiceType
        )
        super.init()
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
    }
    
    deinit {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }
    
    // MARK: - Anunciarse (modo anfitrión)
    
    /// Empieza a anunciar este dispositivo para que otros peers puedan encontrarlo.
    func startAdvertising() {
        guard !isAdvertising else { return }
        advertiser.startAdvertisingPeer()
        isAdvertising = true
    }
    
    /// Detiene el anuncio del dispositivo.
    func stopAdvertising() {
        guard isAdvertising else { return }
        advertiser.stopAdvertisingPeer()
        isAdvertising = false
    }
    
    // MARK: - Buscar peers (modo cliente)
    
    /// Empieza a buscar peers cercanos que se estén anunciando.
    func startBrowsing() {
        guard !isBrowsing else { return }
        discoveredPeers.removeAll()
        browser.startBrowsingForPeers()
        isBrowsing = true
    }
    
    /// Detiene la búsqueda de peers.
    func stopBrowsing() {
        guard isBrowsing else { return }
        browser.stopBrowsingForPeers()
        isBrowsing = false
    }
    
    // MARK: - Conexión
    
    /// Invita a un peer descubierto a unirse a la sesión.
    /// - Parameters:
    ///   - peerID: peer al que se le enviará la invitación.
    ///   - timeout: tiempo máximo de espera para la respuesta. Por defecto 30s.
    func invite(_ peerID: MCPeerID, timeout: TimeInterval = 30) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: timeout)
    }
    
    /// Acepta o rechaza la invitación pendiente, si la hay.
    func accept(_ accept: Bool) {
        guard let handler = pendingInvitationHandler else { return }
        handler(accept, accept ? session : nil)
        pendingInvitationHandler = nil
        pendingInvitationPeer = nil
    }
    
    /// Desconecta este dispositivo de la sesión actual.
    func disconnect() {
        session.disconnect()
    }
    
    // MARK: - Envío de JSON
    
    /// Codifica un objeto `Encodable` a JSON y lo envía a los peers indicados.
    /// Si no se especifican peers, se envía a todos los conectados.
    /// - Returns: `true` si el envío se inició correctamente.
    @discardableResult
    func sendJSON<T: Encodable>(
        _ object: T,
        to peers: [MCPeerID]? = nil,
        mode: MCSessionSendDataMode = .reliable,
        encoder: JSONEncoder = JSONEncoder()
    ) -> Bool {
        let targetPeers = peers ?? session.connectedPeers
        guard !targetPeers.isEmpty else { return false }
        do {
            let data = try encoder.encode(object)
            try session.send(data, toPeers: targetPeers, with: mode)
            return true
        } catch {
            return false
        }
    }
    
    /// Envía datos JSON crudos a los peers indicados.
    @discardableResult
    func sendRawJSON(
        _ data: Data,
        to peers: [MCPeerID]? = nil,
        mode: MCSessionSendDataMode = .reliable
    ) -> Bool {
        let targetPeers = peers ?? session.connectedPeers
        guard !targetPeers.isEmpty else { return false }
        do {
            try session.send(data, toPeers: targetPeers, with: mode)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Decodificación de JSON recibido
    
    /// Decodifica el último JSON recibido en el tipo `Decodable` indicado.
    func decodeLastReceived<T: Decodable>(
        as type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) -> T? {
        guard let data = lastReceivedJSON else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
}

// MARK: - MCSessionDelegate

extension MultipeerManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let mapped: PeerConnectionState
        switch state {
            case .notConnected: mapped = .notConnected
            case .connecting:   mapped = .connecting
            case .connected:    mapped = .connected
            @unknown default:   mapped = .notConnected
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.connectedPeers = session.connectedPeers
            self.onPeerStateChange?(peerID, mapped)
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.lastReceivedJSON = data
            self.lastReceivedFromPeer = peerID
            self.onReceiveJSON?(data, peerID)
        }
    }
    
    // Streams y recursos no se usan en este flujo (solo JSON), pero los métodos son requeridos.
    func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}
    
    func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}
    
    func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if self.automaticallyAcceptInvitations {
                invitationHandler(true, self.session)
                return
            }
            
            self.pendingInvitationPeer = peerID
            self.pendingInvitationHandler = invitationHandler
            self.onInvitationReceived?(peerID)
        }
    }
    
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didNotStartAdvertisingPeer error: Error
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.isAdvertising = false
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    
    func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard !self.discoveredPeers.contains(peerID) else { return }
            self.discoveredPeers.append(peerID)
            self.onPeerDiscovered?(peerID)
            
            if self.automaticallyAcceptInvitations {
                self.invite(peerID)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.discoveredPeers.removeAll { $0 == peerID }
            self.onPeerLost?(peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isBrowsing = false
        }
    }
}
