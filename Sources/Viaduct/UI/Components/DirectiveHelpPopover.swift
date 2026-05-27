import SwiftUI

struct SSHDirective: Codable, Identifiable {
    var id: String { key }
    let key: String
    let description: String
    let example: String
    let manSection: String
}

@MainActor
final class SSHDirectiveLibrary {
    static let shared = SSHDirectiveLibrary()
    let directives: [SSHDirective]
    private(set) var byKey: [String: SSHDirective] = [:]

    private init() {
        guard
            let url = Bundle.main.url(forResource: "SSHDirectives", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let loaded = try? JSONDecoder().decode([SSHDirective].self, from: data)
        else {
            directives = []
            return
        }
        directives = loaded
        byKey = Dictionary(uniqueKeysWithValues: loaded.map { ($0.key, $0) })
    }

    func directive(forKey key: String) -> SSHDirective? {
        byKey[key.trimmingCharacters(in: .whitespaces)]
    }

    func completions(prefix: String) -> [SSHDirective] {
        guard !prefix.isEmpty else { return directives }
        let lower = prefix.lowercased()
        return directives.filter { $0.key.lowercased().hasPrefix(lower) }
    }
}

struct DirectiveHelpPopover: View {
    let directive: SSHDirective

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(directive.key)
                .font(.headline)
            Text(directive.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Example").font(.caption).foregroundStyle(.tertiary)
                Text(directive.example)
                    .font(.system(.caption, design: .monospaced))
                    .padding(6)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
            }
            Text(directive.manSection)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(width: 300)
    }
}
