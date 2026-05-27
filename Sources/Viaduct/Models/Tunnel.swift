import Foundation
import GRDB

enum TunnelType: String, Codable, CaseIterable, DatabaseValueConvertible {
    case local = "local"
    case remote = "remote"
    case dynamic = "dynamic"
}

enum AuthMethod: String, Codable, CaseIterable, DatabaseValueConvertible {
    case systemAgent = "system_agent"
    case onePasswordAgent = "1password_agent"
    case keychainPassphrase = "keychain_passphrase"
}

enum StrictHostChecking: String, Codable, CaseIterable, DatabaseValueConvertible {
    case yes = "yes"
    case no = "no"
    case acceptNew = "accept-new"
    case off = "off"
}

struct SSHOption: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var key: String
    var value: String
}

struct Tunnel: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var isEnabled: Bool
    var type: TunnelType

    // Forwarding
    var localPort: Int?
    var remoteHost: String?
    var remotePort: Int?
    var bindAddress: String?

    // SSH connection
    var host: String
    var user: String?
    var port: Int

    // Auth
    var identityFile: String?
    var proxyJump: String?
    var agentForwarding: Bool
    var authMethod: AuthMethod

    // Behavior
    var autoConnect: Bool
    var strictHostChecking: StrictHostChecking

    // Raw extra options stored as JSON
    var extraOptionsJSON: String

    var createdAt: Date
    var updatedAt: Date

    var extraOptions: [SSHOption] {
        get {
            (try? JSONDecoder().decode([SSHOption].self, from: Data(extraOptionsJSON.utf8))) ?? []
        }
        set {
            extraOptionsJSON = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? "[]"
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        type: TunnelType = .local,
        localPort: Int? = nil,
        remoteHost: String? = nil,
        remotePort: Int? = nil,
        bindAddress: String? = nil,
        host: String,
        user: String? = nil,
        port: Int = 22,
        identityFile: String? = nil,
        proxyJump: String? = nil,
        agentForwarding: Bool = false,
        authMethod: AuthMethod = .systemAgent,
        autoConnect: Bool = false,
        strictHostChecking: StrictHostChecking = .acceptNew,
        extraOptions: [SSHOption] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.type = type
        self.localPort = localPort
        self.remoteHost = remoteHost
        self.remotePort = remotePort
        self.bindAddress = bindAddress
        self.host = host
        self.user = user
        self.port = port
        self.identityFile = identityFile
        self.proxyJump = proxyJump
        self.agentForwarding = agentForwarding
        self.authMethod = authMethod
        self.autoConnect = autoConnect
        self.strictHostChecking = strictHostChecking
        self.extraOptionsJSON = (try? String(data: JSONEncoder().encode(extraOptions), encoding: .utf8)) ?? "[]"
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Tunnel: FetchableRecord, PersistableRecord {
    static let databaseTableName = "tunnels"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let isEnabled = Column(CodingKeys.isEnabled)
        static let type = Column(CodingKeys.type)
        static let localPort = Column(CodingKeys.localPort)
        static let remoteHost = Column(CodingKeys.remoteHost)
        static let remotePort = Column(CodingKeys.remotePort)
        static let bindAddress = Column(CodingKeys.bindAddress)
        static let host = Column(CodingKeys.host)
        static let user = Column(CodingKeys.user)
        static let port = Column(CodingKeys.port)
        static let identityFile = Column(CodingKeys.identityFile)
        static let proxyJump = Column(CodingKeys.proxyJump)
        static let agentForwarding = Column(CodingKeys.agentForwarding)
        static let authMethod = Column(CodingKeys.authMethod)
        static let autoConnect = Column(CodingKeys.autoConnect)
        static let strictHostChecking = Column(CodingKeys.strictHostChecking)
        static let extraOptionsJSON = Column(CodingKeys.extraOptionsJSON)
        static let createdAt = Column(CodingKeys.createdAt)
        static let updatedAt = Column(CodingKeys.updatedAt)
    }
}
