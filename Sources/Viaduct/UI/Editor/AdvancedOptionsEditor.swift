import SwiftUI

struct AdvancedOptionsEditor: View {
    @Binding var options: [SSHOption]
    @State private var helpTarget: SSHDirective?
    @State private var helpAnchorID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if options.isEmpty {
                Text("No extra options. Click + to add raw ssh_config directives.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach($options) { $option in
                    OptionRow(
                        option: $option,
                        onDelete: { remove(option) },
                        onHelp: { dir in
                            helpTarget = dir
                            helpAnchorID = option.id
                        }
                    )
                }
            }

            Button(action: addOption) {
                Label("Add Option", systemImage: "plus.circle")
                    .font(.callout)
            }
            .buttonStyle(.borderless)
            .padding(.top, 2)
        }
        .popover(item: $helpTarget) { directive in
            DirectiveHelpPopover(directive: directive)
        }
    }

    private func addOption() {
        options.append(SSHOption(key: "", value: ""))
    }

    private func remove(_ option: SSHOption) {
        options.removeAll { $0.id == option.id }
    }
}

private struct OptionRow: View {
    @Binding var option: SSHOption
    let onDelete: () -> Void
    let onHelp: (SSHDirective) -> Void

    @State private var showSuggestions = false
    @State private var suggestions: [SSHDirective] = []

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                TextField("Directive", text: $option.key)
                    .font(.system(.callout, design: .monospaced))
                    .frame(minWidth: 160, maxWidth: 200)
                    .onChange(of: option.key) { _, newKey in
                        suggestions = SSHDirectiveLibrary.shared.completions(prefix: newKey)
                        showSuggestions = !suggestions.isEmpty && !newKey.isEmpty
                    }
                    .popover(isPresented: $showSuggestions, arrowEdge: .bottom) {
                        suggestionList
                            .frame(width: 220)
                    }
            }

            Text("=").foregroundStyle(.tertiary)

            TextField("Value", text: $option.value)
                .font(.system(.callout, design: .monospaced))
                .frame(minWidth: 100)

            // Help button
            if let directive = SSHDirectiveLibrary.shared.directive(forKey: option.key) {
                Button(action: { onHelp(directive) }) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("About \(option.key)")
            }

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.8))
            }
            .buttonStyle(.borderless)
        }
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions.prefix(5)) { directive in
                Button(action: {
                    option.key = directive.key
                    showSuggestions = false
                }) {
                    HStack {
                        Text(directive.key)
                            .font(.system(.caption, design: .monospaced))
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .background(Color(.controlBackgroundColor))
            }
        }
        .background(.background)
    }
}
