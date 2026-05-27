import Foundation

enum OnePasswordAgent {
    static let socketPath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    }()

    static var isAvailable: Bool {
        FileManager.default.fileExists(atPath: socketPath)
    }
}
