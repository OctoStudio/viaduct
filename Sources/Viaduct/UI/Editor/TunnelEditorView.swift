import SwiftUI

// MARK: - Editor primitives

private let kLabelWidth: CGFloat = 116

struct EditorSection<Content: View>: View {
    var title: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .tracking(0.5)
                    .padding(.leading, 4)
                    .padding(.bottom, 5)
            }
            VStack(spacing: 0) {
                content
            }
            .background(ViaductStyle.cardBackground, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(ViaductStyle.hairline, lineWidth: 0.5))
        }
    }
}

struct EditorRow<Content: View>: View {
    let label: String
    var required: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(spacing: 2) {
                if required {
                    Text("*").foregroundStyle(.red).font(.caption)
                }
                Text(label)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(width: kLabelWidth, alignment: .trailing)
            .padding(.trailing, 12)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 34)
        .padding(.horizontal, 12)
    }
}

struct EditorDivider: View {
    var body: some View {
        ViaductStyle.hairline
            .frame(height: 0.5)
            .padding(.leading, kLabelWidth + 24)
    }
}

// MARK: - Main editor

struct TunnelEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var appState = AppState.shared

    @State private var name: String
    @State private var host: String
    @State private var user: String
    @State private var port: String
    @State private var type: TunnelType
    @State private var localPort: String
    @State private var remoteHost: String
    @State private var remotePort: String
    @State private var bindAddress: String
    @State private var identityFile: String
    @State private var proxyJump: String
    @State private var agentForwarding: Bool
    @State private var authMethod: AuthMethod
    @State private var autoConnect: Bool
    @State private var strictHostChecking: StrictHostChecking
    @State private var extraOptions: [SSHOption]
    @State private var selectedTagIDs: Set<UUID>

    @State private var showIdentityFilePicker = false
    @State private var nameInvalid = false
    @State private var hostInvalid = false
    @State private var portInvalid = false
    @State private var localPortInvalid = false
    @State private var remoteHostInvalid = false
    @State private var remotePortInvalid = false
    @State private var validationMessage: String?
    @State private var showAdvanced = false
    @FocusState private var focusedField: Field?

    private let existingID: UUID?
    private let isNew: Bool

    enum Field: Hashable { case name, host, user, port, localPort, remoteHost, remotePort }

    init(tunnel: Tunnel?) {
        isNew = tunnel == nil
        existingID = tunnel?.id
        _name         = State(initialValue: tunnel?.name ?? "")
        _host         = State(initialValue: tunnel?.host ?? "")
        _user         = State(initialValue: tunnel?.user ?? "")
        _port         = State(initialValue: tunnel.map { "\($0.port)" } ?? "22")
        _type         = State(initialValue: tunnel?.type ?? .local)
        _localPort    = State(initialValue: tunnel?.localPort.map(String.init) ?? "")
        _remoteHost   = State(initialValue: tunnel?.remoteHost ?? "")
        _remotePort   = State(initialValue: tunnel?.remotePort.map(String.init) ?? "")
        _bindAddress  = State(initialValue: tunnel?.bindAddress ?? "")
        _identityFile = State(initialValue: tunnel?.identityFile ?? "")
        _proxyJump    = State(initialValue: tunnel?.proxyJump ?? "")
        _agentForwarding   = State(initialValue: tunnel?.agentForwarding ?? false)
        let initialAuth = tunnel?.authMethod == .keychainPassphrase ? AuthMethod.systemAgent : (tunnel?.authMethod ?? .systemAgent)
        _authMethod        = State(initialValue: initialAuth)
        _autoConnect       = State(initialValue: tunnel?.autoConnect ?? false)
        _strictHostChecking = State(initialValue: tunnel?.strictHostChecking ?? .acceptNew)
        _extraOptions      = State(initialValue: tunnel?.extraOptions ?? [])
        _selectedTagIDs    = State(initialValue: [])
    }

    var body: some View {
        VStack(spacing: 0) {
            editorToolbar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    identitySection
                    forwardingSection
                    sshSection
                    authSection
                    behaviorSection
                    if !appState.tags.isEmpty { tagsSection }
                    DisclosureGroup(isExpanded: $showAdvanced) {
                        advancedSection.padding(.top, 6)
                    } label: {
                        Text("Advanced Options")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if let msg = validationMessage {
                        validationBanner(msg)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 520)
        .frame(minHeight: 540)
        .onAppear {
            if let id = existingID {
                let tags = (try? TunnelRepository().fetchTags(forTunnel: id)) ?? []
                selectedTagIDs = Set(tags.map(\.id))
            }
            focusedField = isNew ? .name : nil
        }
        .fileImporter(
            isPresented: $showIdentityFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                identityFile = url.path
            }
        }
    }

    // MARK: - Toolbar

    private var editorToolbar: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .keyboardShortcut(.escape, modifiers: [])
            Spacer()
            Text(isNew ? "New Tunnel" : "Edit Tunnel")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            Button(isNew ? "Create" : "Save") { save() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!isValid)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    // MARK: - Identity

    private var identitySection: some View {
        EditorSection {
            EditorRow(label: "Name", required: true) {
                TextField("My Tunnel", text: $name)
                    .textFieldStyle(.plain)
                    .font(.callout)
                    .focused($focusedField, equals: .name)
                    .underlineOnError(nameInvalid)
                    .onChange(of: name) { _, _ in nameInvalid = false }
            }
            EditorDivider()
            EditorRow(label: "Type") {
                Picker("", selection: $type) {
                    Text("Local").tag(TunnelType.local)
                    Text("Remote").tag(TunnelType.remote)
                    Text("Dynamic (SOCKS5)").tag(TunnelType.dynamic)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 300)
            }
        }
    }

    // MARK: - Forwarding

    @ViewBuilder
    private var forwardingSection: some View {
        switch type {
        case .local:
            EditorSection(title: "On This Mac") {
                EditorRow(label: "Local Port") {
                    portTextField($localPort, placeholder: "8080", field: .localPort)
                        .underlineOnError(localPortInvalid)
                        .onChange(of: localPort) { _, _ in localPortInvalid = false }
                }
                EditorDivider()
                EditorRow(label: "Bind Address") {
                    TextField("127.0.0.1", text: $bindAddress)
                        .textFieldStyle(.plain).font(.callout)
                }
            }
            forwardingArrow
            EditorSection(title: "Forward To") {
                EditorRow(label: "Host") {
                    TextField("db.internal", text: $remoteHost)
                        .textFieldStyle(.plain).font(.callout)
                        .focused($focusedField, equals: .remoteHost)
                        .underlineOnError(remoteHostInvalid)
                        .onChange(of: remoteHost) { _, _ in remoteHostInvalid = false }
                }
                EditorDivider()
                EditorRow(label: "Port") {
                    portTextField($remotePort, placeholder: "5432", field: .remotePort)
                        .underlineOnError(remotePortInvalid)
                        .onChange(of: remotePort) { _, _ in remotePortInvalid = false }
                }
            }

        case .remote:
            EditorSection(title: "On Remote Server") {
                EditorRow(label: "Listen Port") {
                    portTextField($remotePort, placeholder: "9090", field: .remotePort)
                        .underlineOnError(remotePortInvalid)
                        .onChange(of: remotePort) { _, _ in remotePortInvalid = false }
                }
            }
            forwardingArrow
            EditorSection(title: "Forward To (This Mac)") {
                EditorRow(label: "Local Port") {
                    portTextField($localPort, placeholder: "9090", field: .localPort)
                        .underlineOnError(localPortInvalid)
                        .onChange(of: localPort) { _, _ in localPortInvalid = false }
                }
                EditorDivider()
                EditorRow(label: "Bind Address") {
                    TextField("127.0.0.1", text: $bindAddress)
                        .textFieldStyle(.plain).font(.callout)
                }
            }

        case .dynamic:
            EditorSection(title: "SOCKS5 Proxy") {
                EditorRow(label: "Listen Port") {
                    portTextField($localPort, placeholder: "1080", field: .localPort)
                        .underlineOnError(localPortInvalid)
                        .onChange(of: localPort) { _, _ in localPortInvalid = false }
                }
                EditorDivider()
                EditorRow(label: "Bind Address") {
                    TextField("127.0.0.1", text: $bindAddress)
                        .textFieldStyle(.plain).font(.callout)
                }
            }
        }
    }

    private var forwardingArrow: some View {
        HStack(spacing: 6) {
            ViaductStyle.hairline.frame(height: 0.5)
            Image(systemName: "arrow.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
            ViaductStyle.hairline.frame(height: 0.5)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - SSH Server

    private var sshSection: some View {
        EditorSection(title: "SSH Server") {
            EditorRow(label: "Host", required: true) {
                HStack(spacing: 8) {
                    TextField("ssh.example.com", text: $host)
                        .textFieldStyle(.plain).font(.callout)
                        .focused($focusedField, equals: .host)
                        .underlineOnError(hostInvalid)
                        .onChange(of: host) { _, _ in hostInvalid = false }
                    Text("Port")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    portTextField($port, placeholder: "22", field: .port)
                        .frame(width: 52)
                        .underlineOnError(portInvalid)
                        .onChange(of: port) { _, _ in portInvalid = false }
                }
            }
            EditorDivider()
            EditorRow(label: "User") {
                TextField(NSUserName(), text: $user)
                    .textFieldStyle(.plain).font(.callout)
                    .focused($focusedField, equals: .user)
            }
            EditorDivider()
            EditorRow(label: "ProxyJump") {
                TextField("user@bastion:22", text: $proxyJump)
                    .textFieldStyle(.plain).font(.callout)
            }
        }
    }

    // MARK: - Authentication

    private var authSection: some View {
        EditorSection(title: "Authentication") {
            EditorRow(label: "Method") {
                Picker("", selection: $authMethod) {
                    Text("System ssh-agent").tag(AuthMethod.systemAgent)
                    if OnePasswordAgent.isAvailable {
                        Text("1Password Agent").tag(AuthMethod.onePasswordAgent)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 220)
            }
            EditorDivider()
            EditorRow(label: "Identity File") {
                HStack(spacing: 6) {
                    TextField("~/.ssh/id_ed25519", text: $identityFile)
                        .textFieldStyle(.plain).font(.callout)
                    Button("Browse…") { showIdentityFilePicker = true }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
            }
            EditorDivider()
            EditorRow(label: "Agent Forwarding") {
                Toggle("", isOn: $agentForwarding).labelsHidden()
            }
        }
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        EditorSection(title: "Behavior") {
            EditorRow(label: "Auto-connect") {
                Toggle("Launch with app", isOn: $autoConnect)
                    .font(.callout)
            }
            EditorDivider()
            EditorRow(label: "Host Key Check") {
                Picker("", selection: $strictHostChecking) {
                    ForEach(StrictHostChecking.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 160)
            }
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        EditorSection(title: "Tags") {
            EditorRow(label: "") {
                TagChipPicker(tags: appState.tags, selectedIDs: $selectedTagIDs)
                    .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        EditorSection {
            AdvancedOptionsEditor(options: $extraOptions)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
    }

    // MARK: - Validation banner

    private func validationBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(10)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color.red.opacity(0.25), lineWidth: 0.5))
    }

    // MARK: - Helpers

    private func portTextField(_ binding: Binding<String>, placeholder: String, field: Field) -> some View {
        TextField(placeholder, text: binding)
            .textFieldStyle(.plain)
            .font(.callout.monospacedDigit())
            .focused($focusedField, equals: field)
            .frame(width: 60)
            .multilineTextAlignment(.leading)
            .onReceive(binding.wrappedValue.publisher.collect()) { chars in
                let filtered = String(chars.filter(\.isNumber))
                if filtered != binding.wrappedValue { binding.wrappedValue = filtered }
            }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !host.trimmingCharacters(in: .whitespaces).isEmpty
            && isValidPort(port)
            && isForwardingValid
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        let h = host.trimmingCharacters(in: .whitespaces)
        validationMessage = nil

        if n.isEmpty {
            nameInvalid = true
            validationMessage = "Enter a tunnel name."
            focusedField = .name; return
        }
        if h.isEmpty {
            hostInvalid = true
            validationMessage = "Enter the SSH server host."
            focusedField = .host; return
        }
        if !isValidPort(port) {
            portInvalid = true
            validationMessage = "Enter an SSH port from 1 to 65535."
            focusedField = .port; return
        }
        guard validateForwarding() else { return }

        let tunnel = Tunnel(
            id: existingID ?? UUID(),
            name: n,
            type: type,
            localPort: Int(localPort),
            remoteHost: remoteHost.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            remotePort: Int(remotePort),
            bindAddress: bindAddress.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            host: h,
            user: user.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            port: Int(port) ?? 22,
            identityFile: identityFile.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            proxyJump: proxyJump.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            agentForwarding: agentForwarding,
            authMethod: authMethod,
            autoConnect: autoConnect,
            strictHostChecking: strictHostChecking,
            extraOptions: extraOptions
        )
        AppState.shared.saveTunnel(tunnel, tagIDs: Array(selectedTagIDs))
        dismiss()
    }

    private var isForwardingValid: Bool {
        switch type {
        case .local:   return isValidPort(localPort) && !remoteHost.trimmingCharacters(in: .whitespaces).isEmpty && isValidPort(remotePort)
        case .remote:  return isValidPort(remotePort) && isValidPort(localPort)
        case .dynamic: return isValidPort(localPort)
        }
    }

    private func validateForwarding() -> Bool {
        localPortInvalid = false; remoteHostInvalid = false; remotePortInvalid = false
        switch type {
        case .local:
            localPortInvalid  = !isValidPort(localPort)
            remoteHostInvalid = remoteHost.trimmingCharacters(in: .whitespaces).isEmpty
            remotePortInvalid = !isValidPort(remotePort)
            if localPortInvalid   { validationMessage = "Enter a local port (1–65535)."; focusedField = .localPort }
            else if remoteHostInvalid { validationMessage = "Enter the remote host to forward to."; focusedField = .remoteHost }
            else if remotePortInvalid { validationMessage = "Enter a remote port (1–65535)."; focusedField = .remotePort }
        case .remote:
            remotePortInvalid = !isValidPort(remotePort)
            localPortInvalid  = !isValidPort(localPort)
            if remotePortInvalid { validationMessage = "Enter a remote listen port (1–65535)."; focusedField = .remotePort }
            else if localPortInvalid { validationMessage = "Enter a local destination port (1–65535)."; focusedField = .localPort }
        case .dynamic:
            localPortInvalid = !isValidPort(localPort)
            if localPortInvalid { validationMessage = "Enter a SOCKS listen port (1–65535)."; focusedField = .localPort }
        }
        return !localPortInvalid && !remoteHostInvalid && !remotePortInvalid
    }

    private func isValidPort(_ value: String) -> Bool {
        guard let p = Int(value) else { return false }
        return (1...65535).contains(p)
    }
}

// MARK: - View helpers

private extension View {
    func underlineOnError(_ invalid: Bool) -> some View {
        overlay(alignment: .bottom) {
            if invalid { Rectangle().fill(Color.red).frame(height: 1.5) }
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

// MARK: - Tag chip picker

struct TagChipPicker: View {
    let tags: [Tag]
    @Binding var selectedIDs: Set<UUID>

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(tags) { tag in
                let selected = selectedIDs.contains(tag.id)
                Button(action: {
                    if selected { selectedIDs.remove(tag.id) } else { selectedIDs.insert(tag.id) }
                }) {
                    HStack(spacing: 4) {
                        Circle().fill(Color(hex: tag.color)).frame(width: 8, height: 8)
                        Text(tag.name).font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        selected ? Color(hex: tag.color).opacity(0.15) : Color(.controlBackgroundColor),
                        in: Capsule()
                    )
                    .overlay(Capsule().stroke(
                        selected ? Color(hex: tag.color).opacity(0.6) : Color(.separatorColor),
                        lineWidth: 0.5
                    ))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Flow layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > width, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX; var y = bounds.minY; var rowH: CGFloat = 0
        for v in subviews {
            let s = v.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            v.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            x += s.width + spacing; rowH = max(rowH, s.height)
        }
    }
}
