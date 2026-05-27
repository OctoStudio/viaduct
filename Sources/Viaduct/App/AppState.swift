import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    static let shared = AppState()

    var tunnels: [Tunnel] = []
    var tags: [Tag] = []
    var tunnelTags: [UUID: [Tag]] = [:]  // tunnelID → tags

    var selectedTunnelID: UUID?
    var isMainWindowOpen = false
    var isEditorPresented = false
    var editingTunnel: Tunnel?

    var searchText = ""
    var selectedSidebarItem: SidebarItem = .allTunnels

    private let repository = TunnelRepository()

    private init() {}

    func loadAll() {
        tunnels = (try? repository.fetchAllTunnels()) ?? []
        tags = (try? repository.fetchAllTags()) ?? []
        tunnelTags = (try? repository.fetchTagsByTunnel()) ?? [:]
    }

    func reload() {
        loadAll()
    }

    var filteredTunnels: [Tunnel] {
        var result = tunnels

        switch selectedSidebarItem {
        case .allTunnels:
            break
        case .connected:
            result = result.filter {
                if case .connected = TunnelManager.shared.state(for: $0.id) { return true }
                return false
            }
        case .errors:
            result = result.filter {
                if case .failed = TunnelManager.shared.state(for: $0.id) { return true }
                return false
            }
        case .tag(let tag):
            result = result.filter { tunnel in
                (tunnelTags[tunnel.id] ?? []).contains(where: { $0.id == tag.id })
            }
        }

        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q)
                || $0.host.lowercased().contains(q)
                || (tunnelTags[$0.id] ?? []).contains { $0.name.lowercased().contains(q) }
            }
        }

        return result
    }

    func saveTunnel(_ tunnel: Tunnel, tagIDs: [UUID]) {
        try? repository.saveTunnel(tunnel)
        try? repository.setTags(tagIDs, forTunnel: tunnel.id)
        loadAll()
    }

    func deleteTunnel(_ tunnel: Tunnel) {
        TunnelManager.shared.stop(tunnelID: tunnel.id)
        try? repository.deleteTunnel(id: tunnel.id)
        loadAll()
    }

    func toggleTunnel(_ tunnel: Tunnel) {
        let state = TunnelManager.shared.state(for: tunnel.id)
        switch state {
        case .stopped, .idle, .failed:
            TunnelManager.shared.start(tunnel: tunnel)
        default:
            TunnelManager.shared.stop(tunnelID: tunnel.id)
        }
    }
}

enum SidebarItem: Hashable {
    case allTunnels
    case connected
    case errors
    case tag(Tag)
}
