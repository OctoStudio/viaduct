import SwiftUI

struct SidebarView: View {
    @State private var appState = AppState.shared

    var body: some View {
        List(selection: $appState.selectedSidebarItem) {
            Section("Smart Groups") {
                Label("All Tunnels", systemImage: "rectangle.connected.to.line.below")
                    .tag(SidebarItem.allTunnels)
                Label("Connected", systemImage: "checkmark.circle.fill")
                    .tag(SidebarItem.connected)
                Label("Errors", systemImage: "exclamationmark.triangle.fill")
                    .tag(SidebarItem.errors)
            }

            if !appState.tags.isEmpty {
                Section("Tags") {
                    ForEach(appState.tags) { tag in
                        HStack {
                            Circle()
                                .fill(Color(hex: tag.color))
                                .frame(width: 10, height: 10)
                            Text(tag.name)
                        }
                        .tag(SidebarItem.tag(tag))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: openEditor) {
                    Image(systemName: "plus")
                }
                .help("New Tunnel (⌘N)")
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }

    private func openEditor() {
        appState.editingTunnel = nil
        appState.isEditorPresented = true
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
