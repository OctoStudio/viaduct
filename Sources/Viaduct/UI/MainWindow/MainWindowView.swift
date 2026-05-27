import SwiftUI

struct MainWindowView: View {
    @State private var appState = AppState.shared

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            TunnelListView()
        } detail: {
            TunnelDetailView()
        }
        .navigationTitle("Viaduct")
        .frame(minWidth: 800, minHeight: 500)
        .onAppear { appState.reload() }
        .sheet(isPresented: $appState.isEditorPresented) {
            TunnelEditorView(tunnel: appState.editingTunnel)
        }
        .keyboardShortcut("n", modifiers: .command)  // handled via toolbar button
    }
}
