import Foundation
import GRDB

// All database access goes through this type.
// Methods are synchronous internally but called from async contexts via Tasks.
struct TunnelRepository {
    private let db: DatabaseQueue

    init(db: DatabaseQueue = appDatabase) {
        self.db = db
    }

    // MARK: - Tunnels

    func fetchAllTunnels() throws -> [Tunnel] {
        try db.read { db in
            try Tunnel.fetchAll(db)
        }
    }

    func fetchTunnel(id: UUID) throws -> Tunnel? {
        try db.read { db in
            try Tunnel.fetchOne(db, key: id.uuidString)
        }
    }

    func fetchAutoConnectTunnels() throws -> [Tunnel] {
        try db.read { db in
            try Tunnel.filter(Tunnel.Columns.autoConnect == true).fetchAll(db)
        }
    }

    func saveTunnel(_ tunnel: Tunnel) throws {
        var t = tunnel
        t.updatedAt = Date()
        try db.write { db in
            try t.save(db)
        }
    }

    func deleteTunnel(id: UUID) throws {
        try db.write { db in
            _ = try Tunnel.deleteOne(db, key: id.uuidString)
        }
    }

    // MARK: - Tags

    func fetchAllTags() throws -> [Tag] {
        try db.read { db in
            try Tag.fetchAll(db)
        }
    }

    func fetchTags(forTunnel tunnelID: UUID) throws -> [Tag] {
        try db.read { db in
            let request = Tag
                .joining(required: Tag.hasMany(TunnelTag.self, using: ForeignKey(["tagID"]))
                    .filter(TunnelTag.Columns.tunnelID == tunnelID.uuidString))
            return try request.fetchAll(db)
        }
    }

    func fetchTagsByTunnel() throws -> [UUID: [Tag]] {
        try db.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT tunnel_tags.tunnelID, tags.id, tags.name, tags.color
                FROM tunnel_tags
                JOIN tags ON tags.id = tunnel_tags.tagID
                ORDER BY tags.name
                """)

            var result: [UUID: [Tag]] = [:]
            for row in rows {
                guard
                    let tunnelID = UUID(uuidString: row["tunnelID"]),
                    let tagID = UUID(uuidString: row["id"])
                else { continue }

                result[tunnelID, default: []].append(Tag(
                    id: tagID,
                    name: row["name"],
                    color: row["color"]
                ))
            }
            return result
        }
    }

    func saveTag(_ tag: Tag) throws {
        try db.write { db in
            try tag.save(db)
        }
    }

    func setTags(_ tagIDs: [UUID], forTunnel tunnelID: UUID) throws {
        try db.write { db in
            try TunnelTag.filter(TunnelTag.Columns.tunnelID == tunnelID.uuidString).deleteAll(db)
            for tagID in tagIDs {
                try TunnelTag(tunnelID: tunnelID, tagID: tagID).insert(db)
            }
        }
    }

    // MARK: - Connection log

    func appendEvent(_ event: ConnectionEvent) throws {
        try db.write { db in
            try event.insert(db)
            // Keep only the last 500 events per tunnel
            let count = try ConnectionEvent
                .filter(ConnectionEvent.Columns.tunnelID == event.tunnelID.uuidString)
                .fetchCount(db)
            if count > 500 {
                try db.execute(sql: """
                    DELETE FROM connection_log
                    WHERE tunnelID = ?
                      AND id IN (
                        SELECT id
                        FROM connection_log
                        WHERE tunnelID = ?
                        ORDER BY timestamp ASC
                        LIMIT ?
                      )
                    """, arguments: [
                        event.tunnelID.uuidString,
                        event.tunnelID.uuidString,
                        count - 500
                    ])
            }
        }
    }

    func fetchRecentEvents(tunnelID: UUID, limit: Int = 100) throws -> [ConnectionEvent] {
        try db.read { db in
            try ConnectionEvent
                .filter(ConnectionEvent.Columns.tunnelID == tunnelID.uuidString)
                .order(ConnectionEvent.Columns.timestamp.desc)
                .limit(limit)
                .fetchAll(db)
        }
    }
}

// MARK: - Column helpers for ConnectionEvent and TunnelTag

extension ConnectionEvent {
    enum Columns {
        static let tunnelID = Column("tunnelID")
        static let timestamp = Column("timestamp")
    }
}

extension TunnelTag {
    enum Columns {
        static let tunnelID = Column("tunnelID")
        static let tagID = Column("tagID")
    }
}

extension Tag {
    static let tunnelTags = hasMany(TunnelTag.self, using: ForeignKey(["tagID"]))
}
