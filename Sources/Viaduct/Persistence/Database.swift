import Foundation
import GRDB

// Shared database pool for the app.
let appDatabase: DatabaseQueue = {
    let fm = FileManager.default
    let appSupport = try! fm.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )
    let dir = appSupport.appendingPathComponent("Viaduct", isDirectory: true)
    try! fm.createDirectory(at: dir, withIntermediateDirectories: true)
    let dbURL = dir.appendingPathComponent("viaduct.db")

    var config = Configuration()
    config.label = "Viaduct"
    let queue = try! DatabaseQueue(path: dbURL.path, configuration: config)
    try! runMigrations(queue)
    return queue
}()

private func runMigrations(_ db: DatabaseQueue) throws {
    var migrator = DatabaseMigrator()

    migrator.registerMigration("v1_initial") { db in
        try db.create(table: "tunnels", ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("name", .text).notNull()
            t.column("isEnabled", .boolean).notNull().defaults(to: true)
            t.column("type", .text).notNull().defaults(to: "local")
            t.column("localPort", .integer)
            t.column("remoteHost", .text)
            t.column("remotePort", .integer)
            t.column("bindAddress", .text)
            t.column("host", .text).notNull()
            t.column("user", .text)
            t.column("port", .integer).notNull().defaults(to: 22)
            t.column("identityFile", .text)
            t.column("proxyJump", .text)
            t.column("agentForwarding", .boolean).notNull().defaults(to: false)
            t.column("authMethod", .text).notNull().defaults(to: "system_agent")
            t.column("autoConnect", .boolean).notNull().defaults(to: false)
            t.column("strictHostChecking", .text).notNull().defaults(to: "accept-new")
            t.column("extraOptionsJSON", .text).notNull().defaults(to: "[]")
            t.column("createdAt", .datetime).notNull()
            t.column("updatedAt", .datetime).notNull()
        }

        try db.create(table: "tags", ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("name", .text).notNull().unique()
            t.column("color", .text).notNull().defaults(to: "#6C6C70")
        }

        try db.create(table: "tunnel_tags", ifNotExists: true) { t in
            t.column("tunnelID", .text)
                .notNull()
                .indexed()
                .references("tunnels", onDelete: .cascade)
            t.column("tagID", .text)
                .notNull()
                .indexed()
                .references("tags", onDelete: .cascade)
            t.primaryKey(["tunnelID", "tagID"])
        }

        try db.create(table: "connection_log", ifNotExists: true) { t in
            t.column("id", .text).primaryKey()
            t.column("tunnelID", .text)
                .notNull()
                .indexed()
                .references("tunnels", onDelete: .cascade)
            t.column("event", .text).notNull()
            t.column("message", .text)
            t.column("timestamp", .datetime).notNull()
        }

        try db.create(
            index: "connection_log_timestamp",
            on: "connection_log",
            columns: ["tunnelID", "timestamp"]
        )
    }

    try migrator.migrate(db)
}
