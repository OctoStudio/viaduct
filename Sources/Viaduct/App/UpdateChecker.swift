import AppKit
import Observation

@MainActor
@Observable
final class UpdateChecker {
    static let shared = UpdateChecker()

    var updateAvailable = false
    var latestVersion: String?

    private init() {}

    func check() {
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: URL(string: "https://api.github.com/repos/OctoStudio/viaduct/releases/latest")!),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String else { return }

            let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"

            if latest.compare(current, options: .numeric) == .orderedDescending {
                latestVersion = latest
                updateAvailable = true
            }
        }
    }

    func openReleasePage() {
        let tag = latestVersion.map { "v\($0)" } ?? ""
        let url = URL(string: "https://github.com/OctoStudio/viaduct/releases/\(tag)")!
        NSWorkspace.shared.open(url)
    }
}
