import Foundation
import GRDB

enum ConnectionEventKind: String, Codable, DatabaseValueConvertible {
    case connected
    case disconnected
    case error
    case reconnecting
}

struct ConnectionEvent: Identifiable, Codable {
    var id: UUID
    var tunnelID: UUID
    var event: ConnectionEventKind
    var message: String?
    var timestamp: Date

    init(
        id: UUID = UUID(),
        tunnelID: UUID,
        event: ConnectionEventKind,
        message: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.tunnelID = tunnelID
        self.event = event
        self.message = message
        self.timestamp = timestamp
    }
}

extension ConnectionEvent: FetchableRecord, PersistableRecord {
    static let databaseTableName = "connection_log"
}
