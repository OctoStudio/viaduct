import Testing
@testable import Viaduct

@Suite("SSHCommandBuilder")
struct SSHCommandBuilderTests {

    private func localTunnel(
        localPort: Int = 8080,
        remoteHost: String = "db.internal",
        remotePort: Int = 5432,
        host: String = "bastion.example.com",
        user: String? = "alice",
        port: Int = 22,
        bindAddress: String? = nil,
        identityFile: String? = nil,
        proxyJump: String? = nil,
        agentForwarding: Bool = false,
        strictHostChecking: StrictHostChecking = .acceptNew,
        extraOptions: [SSHOption] = []
    ) -> Tunnel {
        Tunnel(
            name: "Test",
            type: .local,
            localPort: localPort,
            remoteHost: remoteHost,
            remotePort: remotePort,
            bindAddress: bindAddress,
            host: host,
            user: user,
            port: port,
            identityFile: identityFile,
            proxyJump: proxyJump,
            agentForwarding: agentForwarding,
            strictHostChecking: strictHostChecking,
            extraOptions: extraOptions
        )
    }

    @Test func localForwardingBasic() {
        let t = localTunnel()
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.contains("-N"))
        #expect(args.contains("-L"))
        let idx = args.firstIndex(of: "-L")!
        #expect(args[idx + 1] == "8080:db.internal:5432")
        #expect(args.last == "alice@bastion.example.com")
    }

    @Test func localForwardingWithBindAddress() {
        let t = localTunnel(bindAddress: "0.0.0.0")
        let args = SSHCommandBuilder.buildArguments(for: t)
        let idx = args.firstIndex(of: "-L")!
        #expect(args[idx + 1] == "0.0.0.0:8080:db.internal:5432")
    }

    @Test func dynamicForwarding() {
        let t = Tunnel(name: "SOCKS", type: .dynamic, localPort: 1080, host: "proxy.example.com")
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.contains("-D"))
        let idx = args.firstIndex(of: "-D")!
        #expect(args[idx + 1] == "1080")
    }

    @Test func dynamicForwardingWithBind() {
        let t = Tunnel(name: "SOCKS", type: .dynamic, localPort: 1080, bindAddress: "0.0.0.0", host: "proxy.example.com")
        let args = SSHCommandBuilder.buildArguments(for: t)
        let idx = args.firstIndex(of: "-D")!
        #expect(args[idx + 1] == "0.0.0.0:1080")
    }

    @Test func remoteForwarding() {
        let t = Tunnel(
            name: "Remote",
            type: .remote,
            localPort: 3000,
            remoteHost: "localhost",
            remotePort: 9000,
            host: "server.example.com"
        )
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.contains("-R"))
        let idx = args.firstIndex(of: "-R")!
        #expect(args[idx + 1] == "9000:localhost:3000")
    }

    @Test func nonDefaultPort() {
        let t = localTunnel(port: 2222)
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.contains("-p"))
        let idx = args.firstIndex(of: "-p")!
        #expect(args[idx + 1] == "2222")
    }

    @Test func defaultPortOmitted() {
        let t = localTunnel(port: 22)
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(!args.contains("-p"))
    }

    @Test func proxyJump() {
        let t = localTunnel(proxyJump: "jump@bastion:22")
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.contains("-J"))
        let idx = args.firstIndex(of: "-J")!
        #expect(args[idx + 1] == "jump@bastion:22")
    }

    @Test func agentForwarding() {
        let t = localTunnel(agentForwarding: true)
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.contains("-A"))
    }

    @Test func agentForwardingOmittedByDefault() {
        let t = localTunnel(agentForwarding: false)
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(!args.contains("-A"))
    }

    @Test func identityFile() {
        let t = localTunnel(identityFile: "~/.ssh/id_ed25519")
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.contains("-i"))
    }

    @Test func extraOptions() {
        let opts = [SSHOption(key: "Compression", value: "yes"), SSHOption(key: "ConnectTimeout", value: "5")]
        let t = localTunnel(extraOptions: opts)
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.contains(where: { $0 == "Compression=yes" }))
        #expect(args.contains(where: { $0 == "ConnectTimeout=5" }))
    }

    @Test func strictHostCheckingIncluded() {
        let t = localTunnel(strictHostChecking: .no)
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.contains("StrictHostKeyChecking=no"))
    }

    @Test func alwaysIncludesKeepAliveFlags() {
        let t = localTunnel()
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.contains("ServerAliveInterval=15"))
        #expect(args.contains("ServerAliveCountMax=3"))
        #expect(args.contains("ExitOnForwardFailure=yes"))
    }

    @Test func destinationNoUserWhenNil() {
        let t = Tunnel(name: "T", type: .local, localPort: 80, remoteHost: "h", remotePort: 80, host: "myhost.com")
        let args = SSHCommandBuilder.buildArguments(for: t)
        #expect(args.last == "myhost.com")
    }
}
