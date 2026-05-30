// Viaduct — Tunnel detail (right column)

const { useState: useStateD, useEffect: useEffectD, useMemo: useMemoD } = React;
const { formatUptime: fmtUpD, relativeTime: relTimeD, routeDescription: routeD,
        endpointDescription: endpointD, effectiveCommand: effCmdD, Icon: IconD } = window.ViaductUtils;
const { StatusDot: StatusDotD, TypeChip: TypeChipD, iconButton: iconButtonD } = window.ViaductBits;

const authMethodLabel = {
  system_agent: 'System SSH Agent',
  '1password_agent': '1Password Agent',
  keychain_passphrase: 'Keychain Passphrase',
};

function DetailEmpty({ tokens }) {
  return (
    <section style={{
      flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: tokens.contentBg,
      color: tokens.textTertiary,
    }}>
      <div style={{ textAlign: 'center', maxWidth: 320 }}>
        <div style={{
          width: 56, height: 56, borderRadius: 14,
          background: tokens.surface, display: 'inline-flex',
          alignItems: 'center', justifyContent: 'center', marginBottom: 14,
        }}>
          <IconD name="globe" size={26} color={tokens.textTertiary} />
        </div>
        <div style={{ fontSize: 17, fontWeight: 600, color: tokens.text, marginBottom: 6, letterSpacing: -0.2 }}>
          Select a Tunnel
        </div>
        <div style={{ fontSize: 12.5, color: tokens.textSecondary, lineHeight: 1.5 }}>
          Choose a tunnel from the list to see its status, route, and recent activity.
        </div>
      </div>
    </section>
  );
}

function StatusBanner({ tunnel, tokens, onToggle, onRestart }) {
  const isRunning = ['connected', 'connecting', 'reconnecting'].includes(tunnel.state);
  const label = ({
    connected: 'Connected', connecting: 'Connecting…',
    reconnecting: 'Reconnecting…', failed: 'Connection failed',
    idle: 'Idle', stopped: 'Stopped',
  })[tunnel.state];

  const accent = ({
    connected: tokens.success, connecting: tokens.warn,
    reconnecting: tokens.warn, failed: tokens.danger,
    idle: tokens.muted, stopped: tokens.muted,
  })[tunnel.state];

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 14,
      padding: '18px 20px',
      background: `${accent}0d`,
      borderRadius: 12,
      border: `0.5px solid ${accent}30`,
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: '50%',
        background: `${accent}1f`, display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        position: 'relative', flexShrink: 0,
      }}>
        <StatusDotD state={tunnel.state} tokens={tokens} size={12} />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: tokens.text, letterSpacing: -0.1 }}>
          {label}
        </div>
        <div style={{ fontSize: 12, color: tokens.textSecondary, marginTop: 2 }}>
          {tunnel.state === 'connected' && `Stable for ${fmtUpD(tunnel.uptimeSec)} · ${endpointD(tunnel)}`}
          {tunnel.state === 'connecting' && `Establishing channel to ${tunnel.host}`}
          {tunnel.state === 'reconnecting' && `Retrying connection to ${tunnel.host}`}
          {tunnel.state === 'failed' && (tunnel.errorMessage || 'Tunnel exited unexpectedly')}
          {(tunnel.state === 'idle' || tunnel.state === 'stopped') && `Ready to connect to ${tunnel.host}`}
        </div>
      </div>
      <div style={{ display: 'flex', gap: 6 }}>
        <PrimaryButton tokens={tokens} accent={isRunning ? tokens.danger : tokens.accent} onClick={onToggle}>
          <IconD name={isRunning ? 'stop' : 'play'} size={10} color="#fff" />
          <span>{isRunning ? 'Stop' : 'Connect'}</span>
        </PrimaryButton>
        <SecondaryButton tokens={tokens} disabled={!isRunning} onClick={onRestart}>
          <IconD name="refresh" size={11} color={isRunning ? tokens.text : tokens.textTertiary} />
        </SecondaryButton>
      </div>
    </div>
  );
}

function PrimaryButton({ children, onClick, accent, tokens }) {
  return (
    <button onClick={onClick} style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: '0 12px', height: 26, borderRadius: 6,
      border: 'none', cursor: 'default',
      background: accent || tokens.accent, color: '#fff',
      fontSize: 12, fontWeight: 600, letterSpacing: -0.1,
      boxShadow: `0 1px 2px ${accent || tokens.accent}50, inset 0 1px 0 rgba(255,255,255,0.18)`,
    }}>{children}</button>
  );
}

function SecondaryButton({ children, onClick, disabled, tokens }) {
  return (
    <button onClick={onClick} disabled={disabled} style={{
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 5,
      padding: '0 10px', minWidth: 26, height: 26, borderRadius: 6,
      cursor: 'default',
      background: tokens.surface, color: tokens.text,
      border: `0.5px solid ${tokens.border}`,
      fontSize: 12, fontWeight: 500,
      opacity: disabled ? 0.4 : 1,
    }}>{children}</button>
  );
}

// ─────────────────────────────────────────────────────────────
// Detail rows
// ─────────────────────────────────────────────────────────────
function SectionCard({ title, action, children, tokens }) {
  return (
    <div style={{ marginBottom: 18 }}>
      <div style={{
        display: 'flex', alignItems: 'baseline', marginBottom: 6, padding: '0 2px',
      }}>
        <div style={{
          fontSize: 11, fontWeight: 600, letterSpacing: 0.3,
          color: tokens.textTertiary, textTransform: 'uppercase',
        }}>{title}</div>
        <div style={{ marginLeft: 'auto' }}>{action}</div>
      </div>
      <div style={{
        background: tokens.surface,
        border: `0.5px solid ${tokens.border}`,
        borderRadius: 10, overflow: 'hidden',
      }}>{children}</div>
    </div>
  );
}

function KVRow({ label, value, mono, last, tokens, action }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '8px 14px',
      borderBottom: last ? 'none' : `0.5px solid ${tokens.hairline}`,
      minHeight: 32,
    }}>
      <div style={{
        width: 130, flexShrink: 0,
        fontSize: 12, color: tokens.textSecondary,
      }}>{label}</div>
      <div style={{
        flex: 1, minWidth: 0,
        fontSize: 12.5, color: tokens.text,
        fontFamily: mono ? 'ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace' : 'inherit',
        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
        letterSpacing: mono ? -0.1 : 0,
      }}>{value}</div>
      {action}
    </div>
  );
}

function CopyButton({ value, tokens }) {
  const [copied, setCopied] = useStateD(false);
  return (
    <button onClick={(e) => {
      e.stopPropagation();
      try { navigator.clipboard.writeText(value); } catch {}
      setCopied(true);
      setTimeout(() => setCopied(false), 1200);
    }} style={{
      ...iconButtonD(tokens), width: 22, height: 22, opacity: copied ? 1 : 0.55,
    }} title="Copy">
      <IconD name={copied ? 'check' : 'copy'} size={11}
        color={copied ? tokens.success : tokens.textSecondary} />
    </button>
  );
}

function eventIcon(kind, tokens) {
  switch (kind) {
    case 'connected':    return { name: 'check', color: tokens.success };
    case 'disconnected': return { name: 'sleep', color: tokens.muted };
    case 'error':        return { name: 'warn',  color: tokens.danger };
    case 'reconnecting': return { name: 'refresh', color: tokens.warn };
    default: return { name: 'circle', color: tokens.muted };
  }
}

function TunnelDetail({
  tunnel, tokens, onToggle, onRestart, onEdit, onDelete,
}) {
  if (!tunnel) return <DetailEmpty tokens={tokens} />;
  const [showCmd, setShowCmd] = useStateD(false);
  const cmd = effCmdD(tunnel);

  return (
    <section style={{
      flex: 1, display: 'flex', flexDirection: 'column',
      background: tokens.contentBg, minWidth: 0,
    }}>
      {/* Title bar */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '0 18px', height: 42, flexShrink: 0,
        borderBottom: `0.5px solid ${tokens.hairline}`,
        background: tokens.titlebarBg,
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
      }}>
        <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
          <span style={{
            fontSize: 14, fontWeight: 600, color: tokens.text, letterSpacing: -0.2,
            whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
          }}>{tunnel.name}</span>
          <TypeChipD type={tunnel.type} tokens={tokens} />
        </div>
        <button onClick={onEdit} style={iconButtonD(tokens)} title="Edit">
          <IconD name="pencil" size={13} color={tokens.text} />
        </button>
        <button onClick={onDelete} style={iconButtonD(tokens)} title="Delete">
          <IconD name="trash" size={13} color={tokens.text} />
        </button>
        <span style={{ width: 1, height: 14, background: tokens.border, margin: '0 2px' }} />
        <button onClick={() => setShowCmd(s => !s)} style={{
          ...iconButtonD(tokens, showCmd),
        }} title="Show command">
          <IconD name="terminal" size={13} color={tokens.text} />
        </button>
      </div>

      {/* Scroll body */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '18px 22px 30px' }}>
        <StatusBanner tunnel={tunnel} tokens={tokens} onToggle={onToggle} onRestart={onRestart} />

        {/* metrics row */}
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8, margin: '14px 0 18px',
        }}>
          <MetricTile tokens={tokens} label="Uptime"
            value={tunnel.state === 'connected' ? fmtUpD(tunnel.uptimeSec) : '—'} />
          <MetricTile tokens={tokens} label="Endpoint"
            value={endpointD(tunnel) || '—'} mono />
          <MetricTile tokens={tokens} label="Auth"
            value={authMethodLabel[tunnel.authMethod]} />
          <MetricTile tokens={tokens} label="Auto-Connect"
            value={tunnel.autoConnect ? 'On' : 'Off'}
            valueColor={tunnel.autoConnect ? tokens.accent : tokens.textSecondary} />
        </div>

        <SectionCard title="Forwarding" tokens={tokens}>
          <KVRow label="Type" value={({ local: 'Local Forward', remote: 'Remote Forward', dynamic: 'Dynamic (SOCKS)' })[tunnel.type]} tokens={tokens} />
          <KVRow label="Route" mono value={routeD(tunnel)} tokens={tokens} />
          {tunnel.type === 'local' && (
            <>
              <KVRow label="Local Port" mono value={`${tunnel.bindAddress || '127.0.0.1'}:${tunnel.localPort}`} tokens={tokens} />
              <KVRow label="Remote Target" mono value={`${tunnel.remoteHost}:${tunnel.remotePort}`} tokens={tokens} last />
            </>
          )}
          {tunnel.type === 'remote' && (
            <>
              <KVRow label="Remote Listen" mono value={`${tunnel.host}:${tunnel.remotePort}`} tokens={tokens} />
              <KVRow label="Forwards To" mono value={`${tunnel.remoteHost || 'localhost'}:${tunnel.localPort}`} tokens={tokens} last />
            </>
          )}
          {tunnel.type === 'dynamic' && (
            <KVRow label="SOCKS Port" mono value={`${tunnel.bindAddress || '127.0.0.1'}:${tunnel.localPort}`} tokens={tokens} last />
          )}
        </SectionCard>

        <SectionCard title="Connection" tokens={tokens}>
          <KVRow label="Host" mono value={`${tunnel.host}:${tunnel.port}`} tokens={tokens}
            action={<CopyButton value={`${tunnel.host}:${tunnel.port}`} tokens={tokens} />} />
          {tunnel.user && <KVRow label="User" mono value={tunnel.user} tokens={tokens} />}
          {tunnel.proxyJump && <KVRow label="ProxyJump" mono value={tunnel.proxyJump} tokens={tokens} />}
          <KVRow label="Strict Host Check" value="accept-new" tokens={tokens} last />
        </SectionCard>

        <SectionCard title="Authentication" tokens={tokens}>
          <KVRow label="Method"
            value={
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                <IconD name="key" size={11} color={tokens.textSecondary} />
                {authMethodLabel[tunnel.authMethod]}
              </span>
            } tokens={tokens} />
          {tunnel.identityFile && <KVRow label="Identity File" mono value={tunnel.identityFile} tokens={tokens} />}
          <KVRow label="Agent Forwarding" value={tunnel.agentForwarding ? 'Enabled' : 'Disabled'} tokens={tokens} last />
        </SectionCard>

        {showCmd && (
          <SectionCard title="Effective Command" tokens={tokens}
            action={<CopyButton value={cmd} tokens={tokens} />}>
            <div style={{
              padding: '12px 14px', fontSize: 11.5,
              fontFamily: 'ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace',
              color: tokens.text, letterSpacing: -0.1, lineHeight: 1.55,
              whiteSpace: 'pre-wrap', wordBreak: 'break-all',
            }}>{cmd}</div>
          </SectionCard>
        )}

        <SectionCard title="Recent Activity" tokens={tokens}>
          {tunnel.events.length === 0 ? (
            <div style={{
              padding: '14px 16px', fontSize: 12, color: tokens.textTertiary,
              display: 'flex', alignItems: 'center', gap: 8,
            }}>
              <IconD name="circle" size={11} color={tokens.textTertiary} />
              <span>No activity yet</span>
            </div>
          ) : tunnel.events.map((e, idx) => {
            const { name, color } = eventIcon(e.kind, tokens);
            return (
              <div key={idx} style={{
                display: 'flex', alignItems: 'center', gap: 10,
                padding: '8px 14px', minHeight: 36,
                borderBottom: idx === tunnel.events.length - 1 ? 'none' : `0.5px solid ${tokens.hairline}`,
              }}>
                <span style={{
                  width: 20, height: 20, borderRadius: '50%',
                  background: `${color}1a`,
                  display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <IconD name={name} size={10} color={color} />
                </span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 12.5, color: tokens.text, fontWeight: 500 }}>
                    {({ connected: 'Connected', disconnected: 'Disconnected', error: 'Error', reconnecting: 'Reconnecting' })[e.kind]}
                  </div>
                  {e.message && (
                    <div style={{ fontSize: 11, color: tokens.textSecondary, marginTop: 1 }}>
                      {e.message}
                    </div>
                  )}
                </div>
                <div style={{
                  fontSize: 11, color: tokens.textTertiary,
                  fontVariantNumeric: 'tabular-nums', flexShrink: 0,
                }}>{relTimeD(e.t)}</div>
              </div>
            );
          })}
        </SectionCard>

        {/* tags */}
        {tunnel.tags && tunnel.tags.length > 0 && (
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginTop: 4 }}>
            {tunnel.tags.map(tagId => {
              const tag = window.ViaductData.TAGS.find(t => t.id === tagId);
              if (!tag) return null;
              return (
                <span key={tagId} style={{
                  display: 'inline-flex', alignItems: 'center', gap: 5,
                  padding: '3px 8px', borderRadius: 10,
                  background: `${tag.color}1a`, border: `0.5px solid ${tag.color}40`,
                  fontSize: 11, fontWeight: 500, color: tokens.text,
                }}>
                  <span style={{ width: 6, height: 6, borderRadius: '50%', background: tag.color }} />
                  {tag.name}
                </span>
              );
            })}
          </div>
        )}
      </div>
    </section>
  );
}

function MetricTile({ label, value, mono, valueColor, tokens }) {
  return (
    <div style={{
      background: tokens.surface,
      border: `0.5px solid ${tokens.border}`,
      borderRadius: 8, padding: '10px 12px',
      minWidth: 0,
    }}>
      <div style={{
        fontSize: 10, fontWeight: 600, letterSpacing: 0.3,
        color: tokens.textTertiary, textTransform: 'uppercase', marginBottom: 4,
      }}>{label}</div>
      <div style={{
        fontSize: 13, fontWeight: 600,
        color: valueColor || tokens.text,
        fontFamily: mono ? 'ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace' : 'inherit',
        letterSpacing: mono ? -0.2 : -0.1,
        whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
      }}>{value}</div>
    </div>
  );
}

window.ViaductDetail = TunnelDetail;
