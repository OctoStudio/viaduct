import SwiftUI

struct MainWindowView: View {
    @State private var appState = AppState.shared
    @AppStorage(AppSettings.appearanceKey) private var appearance = AppAppearance.system.rawValue

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
            if appState.selectedSidebarItem == .settings {
                MainSettingsView()
            } else {
                TunnelListView()
                TunnelDetailView()
            }
        }
        .frame(minWidth: 1180, idealWidth: 1420, minHeight: 620, idealHeight: 760)
        .ignoresSafeArea(.container, edges: [.top, .leading])
        .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
        .onAppear { appState.reload() }
        .sheet(isPresented: $appState.isEditorPresented) {
            TunnelEditorView(tunnel: appState.editingTunnel)
        }
        .sheet(isPresented: $appState.isAboutPresented) {
            AboutView()
                .background(ViaductStyle.detailBackground)
        }
        .keyboardShortcut("n", modifiers: .command)  // handled via toolbar button
    }
}
