import Foundation

struct SSHCommandBuilder {
    static func buildArguments(for tunnel: Tunnel, sshAuthSock: String? = nil) -> [String] {
        var args: [String] = []

        // Base flags
        args += ["-N"]
        args += ["-o", "ServerAliveInterval=15"]
        args += ["-o", "ServerAliveCountMax=3"]
        args += ["-o", "ExitOnForwardFailure=yes"]
        args += ["-o", "StrictHostKeyChecking=\(tunnel.strictHostChecking.rawValue)"]
        if tunnel.authMethod != .keychainPassphrase {
            args += ["-o", "BatchMode=yes"]
        }

        // Port
        if tunnel.port != 22 {
            args += ["-p", "\(tunnel.port)"]
        }

        // Identity file
        if let identityFile = tunnel.identityFile, !identityFile.isEmpty {
            args += ["-i", (identityFile as NSString).expandingTildeInPath]
        }

        // ProxyJump
        if let proxyJump = tunnel.proxyJump, !proxyJump.isEmpty {
            args += ["-J", proxyJump]
        }

        // Agent forwarding
        if tunnel.agentForwarding {
            args += ["-A"]
        }

        // Forwarding type
        switch tunnel.type {
        case .local:
            if let localPort = tunnel.localPort,
               let remoteHost = tunnel.remoteHost,
               let remotePort = tunnel.remotePort {
                let spec = forwardSpec(
                    bind: tunnel.bindAddress,
                    port1: localPort,
                    host: remoteHost,
                    port2: remotePort
                )
                args += ["-L", spec]
            }

        case .remote:
            if let localPort = tunnel.localPort,
               let remotePort = tunnel.remotePort {
                let remoteHost = tunnel.remoteHost ?? "localhost"
                let spec = forwardSpec(
                    bind: tunnel.bindAddress,
                    port1: remotePort,
                    host: remoteHost,
                    port2: localPort
                )
                args += ["-R", spec]
            }

        case .dynamic:
            if let localPort = tunnel.localPort {
                if let bind = tunnel.bindAddress, !bind.isEmpty {
                    args += ["-D", "\(bind):\(localPort)"]
                } else {
                    args += ["-D", "\(localPort)"]
                }
            }
        }

        // Extra raw options
        for option in tunnel.extraOptions {
            if !option.key.isEmpty {
                args += ["-o", "\(option.key)=\(option.value)"]
            }
        }

        // Destination: [user@]host
        let destination: String
        if let user = tunnel.user, !user.isEmpty {
            destination = "\(user)@\(tunnel.host)"
        } else {
            destination = tunnel.host
        }
        args.append(destination)

        return args
    }

    static func buildEnvironment(for tunnel: Tunnel, base: [String: String] = ProcessInfo.processInfo.environment) -> [String: String] {
        var env = base
        // PATH must include /usr/bin for ssh
        if let path = env["PATH"], !path.contains("/usr/bin") {
            env["PATH"] = "/usr/bin:/bin:" + path
        } else if env["PATH"] == nil {
            env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
        }

        switch tunnel.authMethod {
        case .onePasswordAgent:
            let sock = OnePasswordAgent.socketPath
            env["SSH_AUTH_SOCK"] = sock
        case .systemAgent:
            break // inherit from environment
        case .keychainPassphrase:
            // SSH_ASKPASS handled separately; don't override SSH_AUTH_SOCK
            env.removeValue(forKey: "SSH_AUTH_SOCK")
        }

        return env
    }

    // MARK: - Private helpers

    private static func forwardSpec(bind: String?, port1: Int, host: String, port2: Int) -> String {
        if let bind = bind, !bind.isEmpty {
            return "\(bind):\(port1):\(host):\(port2)"
        }
        return "\(port1):\(host):\(port2)"
    }
}
