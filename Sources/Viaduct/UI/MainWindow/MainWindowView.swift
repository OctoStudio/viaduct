import SwiftUI

struct MainWindowView: View {
    @State private var appState = AppState.shared
    @AppStorage(AppSettings.appearanceKey) private var appearance = AppAppearance.system.rawValue

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
            TunnelListView()
            TunnelDetailView()
        }
        .frame(minWidth: 900, idealWidth: 1140, minHeight: 560, idealHeight: 720)
        .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
        .onAppear { appState.reload() }
        .sheet(isPresented: $appState.isEditorPresented) {
            TunnelEditorView(tunnel: appState.editingTunnel)
        }
        .keyboardShortcut("n", modifiers: .command)  // handled via toolbar button
    }
}
