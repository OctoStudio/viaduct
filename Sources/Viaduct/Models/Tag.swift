import Foundation
import GRDB

struct Tag: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var color: String  // hex string e.g. "#FF5733"

    init(id: UUID = UUID(), name: String, color: String = "#6C6C70") {
        self.id = id
        self.name = name
        self.color = color
    }
}

extension Tag: FetchableRecord, PersistableRecord {
    static let databaseTableName = "tags"
}

struct TunnelTag: Codable, FetchableRecord, PersistableRecord {
    var tunnelID: UUID
    var tagID: UUID

    static let databaseTableName = "tunnel_tags"
}
