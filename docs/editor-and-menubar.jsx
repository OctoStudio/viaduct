// Viaduct — Editor sheet + Menu bar popover

const { useState: useStateE, useEffect: useEffectE } = React;
const { Icon: IconE, routeDescription: routeE } = window.ViaductUtils;
const { StatusDot: StatusDotE, TypeChip: TypeChipE, iconButton: iconButtonE } = window.ViaductBits;

// ─────────────────────────────────────────────────────────────
// Editor sheet (modal)
// ─────────────────────────────────────────────────────────────
function EditorSheet({ tunnel, onClose, onSave, tokens, dark }) {
  const [form, setForm] = useStateE(tunnel || {
    id: 'new-' + Date.now(),
    name: '', type: 'local',
    host: '', user: '', port: 22,
    localPort: 8080, remoteHost: 'localhost', remotePort: 8080,
    bindAddress: '127.0.0.1',
    identityFile: '~/.ssh/id_ed25519',
    authMethod: 'system_agent',
    autoConnect: false, agentForwarding: false,
    state: 'idle', uptimeSec: 0, tags: [], events: [],
  });
  const upd = (k, v) => setForm(f => ({ ...f, [k]: v }));

  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 100,
      background: 'rgba(0,0,0,0.18)',
      display: 'flex', alignItems: 'flex-start', justifyContent: 'center',
      paddingTop: 48,
      animation: 'viaFadeIn 180ms ease-out',
    }}
      onClick={onClose}
    >
      <div onClick={(e) => e.stopPropagation()} style={{
        width: 520, maxHeight: 'calc(100% - 96px)', overflowY: 'auto',
        background: tokens.contentBg, borderRadius: 12,
        boxShadow: tokens.shadow,
        border: `0.5px solid ${tokens.border}`,
        animation: 'viaSlideDown 220ms ease-out',
      }}>
        {/* Sheet header */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '14px 18px', borderBottom: `0.5px solid ${tokens.hairline}`,
        }}>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: tokens.text, letterSpacing: -0.1 }}>
              {tunnel ? 'Edit Tunnel' : 'New Tunnel'}
            </div>
            <div style={{ fontSize: 11.5, color: tokens.textSecondary, marginTop: 1 }}>
              Configure how Viaduct connects and forwards.
            </div>
          </div>
          <button onClick={onClose} style={iconButtonE(tokens)}>
            <IconE name="x" size={12} color={tokens.text} />
          </button>
        </div>

        <div style={{ padding: '14px 18px' }}>
          <FormGroup label="Name" tokens={tokens}>
            <TextInput value={form.name} onChange={v => upd('name', v)} placeholder="e.g. Postgres staging" tokens={tokens} />
          </FormGroup>

          <FormGroup label="Tunnel Type" tokens={tokens}>
            <Segmented value={form.type} options={[
              { v: 'local', l: 'Local' },
              { v: 'remote', l: 'Remote' },
              { v: 'dynamic', l: 'Dynamic (SOCKS)' },
            ]} onChange={v => upd('type', v)} tokens={tokens} />
          </FormGroup>

          <FieldRow tokens={tokens}>
            <FormGroup label="Host" tokens={tokens} grow>
              <TextInput mono value={form.host} onChange={v => upd('host', v)} placeholder="bastion.example.com" tokens={tokens} />
            </FormGroup>
            <FormGroup label="Port" tokens={tokens} width={86}>
              <TextInput mono value={form.port} onChange={v => upd('port', parseInt(v) || 22)} tokens={tokens} />
            </FormGroup>
            <FormGroup label="User" tokens={tokens} width={120}>
              <TextInput mono value={form.user} onChange={v => upd('user', v)} placeholder="user" tokens={tokens} />
            </FormGroup>
          </FieldRow>

          {form.type === 'local' && (
            <FieldRow tokens={tokens}>
              <FormGroup label="Bind" tokens={tokens} width={120}>
                <TextInput mono value={form.bindAddress} onChange={v => upd('bindAddress', v)} tokens={tokens} />
              </FormGroup>
              <FormGroup label="Local Port" tokens={tokens} width={100}>
                <TextInput mono value={form.localPort} onChange={v => upd('localPort', parseInt(v) || 0)} tokens={tokens} />
              </FormGroup>
              <FormGroup label="Remote Host" tokens={tokens} grow>
                <TextInput mono value={form.remoteHost} onChange={v => upd('remoteHost', v)} placeholder="localhost" tokens={tokens} />
              </FormGroup>
              <FormGroup label="Remote Port" tokens={tokens} width={100}>
                <TextInput mono value={form.remotePort} onChange={v => upd('remotePort', parseInt(v) || 0)} tokens={tokens} />
              </FormGroup>
            </FieldRow>
          )}

          {form.type === 'remote' && (
            <FieldRow tokens={tokens}>
              <FormGroup label="Remote Port" tokens={tokens} width={120}>
                <TextInput mono value={form.remotePort} onChange={v => upd('remotePort', parseInt(v) || 0)} tokens={tokens} />
              </FormGroup>
              <FormGroup label="Local Target" tokens={tokens} grow>
                <TextInput mono value={form.remoteHost} onChange={v => upd('remoteHost', v)} placeholder="localhost" tokens={tokens} />
              </FormGroup>
              <FormGroup label="Local Port" tokens={tokens} width={100}>
                <TextInput mono value={form.localPort} onChange={v => upd('localPort', parseInt(v) || 0)} tokens={tokens} />
              </FormGroup>
            </FieldRow>
          )}

          {form.type === 'dynamic' && (
            <FieldRow tokens={tokens}>
              <FormGroup label="Bind" tokens={tokens} width={140}>
                <TextInput mono value={form.bindAddress} onChange={v => upd('bindAddress', v)} tokens={tokens} />
              </FormGroup>
              <FormGroup label="SOCKS Port" tokens={tokens} grow>
                <TextInput mono value={form.localPort} onChange={v => upd('localPort', parseInt(v) || 0)} tokens={tokens} />
              </FormGroup>
            </FieldRow>
          )}

          <FormGroup label="Authentication" tokens={tokens}>
            <Segmented value={form.authMethod} options={[
              { v: 'system_agent', l: 'System Agent' },
              { v: '1password_agent', l: '1Password' },
              { v: 'keychain_passphrase', l: 'Passphrase' },
            ]} onChange={v => upd('authMethod', v)} tokens={tokens} />
          </FormGroup>

          <FormGroup label="Identity File" tokens={tokens}>
            <TextInput mono value={form.identityFile} onChange={v => upd('identityFile', v)} tokens={tokens} />
          </FormGroup>

          <div style={{
            display: 'flex', gap: 12, padding: '8px 0',
            borderTop: `0.5px solid ${tokens.hairline}`,
            borderBottom: `0.5px solid ${tokens.hairline}`,
            margin: '14px 0 0',
          }}>
            <Toggle label="Auto-connect on launch" value={form.autoConnect} onChange={v => upd('autoConnect', v)} tokens={tokens} />
            <Toggle label="Forward SSH agent" value={form.agentForwarding} onChange={v => upd('agentForwarding', v)} tokens={tokens} />
          </div>
        </div>

        {/* Footer */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8, padding: '12px 18px',
          borderTop: `0.5px solid ${tokens.hairline}`,
          background: tokens.surface,
        }}>
          <div style={{ fontSize: 11, color: tokens.textTertiary, flex: 1, fontFamily: 'ui-monospace, SFMono-Regular, monospace' }}>
            {form.host && routeE(form)}
          </div>
          <button onClick={onClose} style={{
            padding: '0 14px', height: 26, borderRadius: 6,
            background: tokens.surface, border: `0.5px solid ${tokens.border}`,
            color: tokens.text, fontSize: 12.5, fontWeight: 500, cursor: 'default',
          }}>Cancel</button>
          <button onClick={() => onSave(form)} disabled={!form.name || !form.host} style={{
            padding: '0 14px', height: 26, borderRadius: 6, border: 'none',
            background: tokens.accent, color: '#fff',
            fontSize: 12.5, fontWeight: 600, cursor: 'default',
            opacity: (!form.name || !form.host) ? 0.4 : 1,
            boxShadow: `0 1px 2px ${tokens.accent}40, inset 0 1px 0 rgba(255,255,255,0.18)`,
          }}>{tunnel ? 'Save' : 'Create Tunnel'}</button>
        </div>
      </div>
    </div>
  );
}

function FormGroup({ label, children, tokens, grow, width }) {
  return (
    <div style={{ marginBottom: 12, flex: grow ? 1 : 'none', width: width || 'auto', minWidth: 0 }}>
      <div style={{
        fontSize: 11, fontWeight: 600, color: tokens.textSecondary,
        marginBottom: 4, letterSpacing: 0,
      }}>{label}</div>
      {children}
    </div>
  );
}

function FieldRow({ children, tokens }) {
  return <div style={{ display: 'flex', gap: 10 }}>{children}</div>;
}

function TextInput({ value, onChange, placeholder, mono, tokens }) {
  return (
    <input
      value={value ?? ''}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      style={{
        width: '100%', height: 26, padding: '0 8px',
        borderRadius: 5,
        background: tokens.inputBg,
        border: `0.5px solid ${tokens.inputBorder}`,
        color: tokens.text, fontSize: 12.5,
        fontFamily: mono ? 'ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace' : 'inherit',
        outline: 'none', boxSizing: 'border-box',
        letterSpacing: mono ? -0.1 : 0,
      }}
      onFocus={(e) => { e.target.style.borderColor = tokens.accent; e.target.style.boxShadow = `0 0 0 3px ${tokens.accent}25`; }}
      onBlur={(e) => { e.target.style.borderColor = tokens.inputBorder; e.target.style.boxShadow = 'none'; }}
    />
  );
}

function Segmented({ value, options, onChange, tokens }) {
  return (
    <div style={{
      display: 'flex', padding: 2, gap: 2,
      background: tokens.inputBg, borderRadius: 6,
      border: `0.5px solid ${tokens.inputBorder}`,
    }}>
      {options.map(opt => {
        const sel = value === opt.v;
        return (
          <button key={opt.v} onClick={() => onChange(opt.v)} style={{
            flex: 1, height: 22, border: 'none', borderRadius: 4,
            background: sel ? tokens.contentBg : 'transparent',
            color: sel ? tokens.text : tokens.textSecondary,
            fontSize: 11.5, fontWeight: sel ? 600 : 500, cursor: 'default',
            boxShadow: sel ? `0 1px 2px rgba(0,0,0,0.07), 0 0 0 0.5px ${tokens.border}` : 'none',
            transition: 'all 100ms',
          }}>{opt.l}</button>
        );
      })}
    </div>
  );
}

function Toggle({ value, onChange, label, tokens }) {
  return (
    <label style={{
      display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: tokens.text,
      cursor: 'default', userSelect: 'none', flex: 1,
    }}>
      <span onClick={() => onChange(!value)} style={{
        width: 28, height: 16, borderRadius: 8, position: 'relative',
        background: value ? tokens.accent : tokens.inputBorder,
        transition: 'background 180ms',
      }}>
        <span style={{
          position: 'absolute', top: 1, left: value ? 13 : 1,
          width: 14, height: 14, borderRadius: '50%', background: '#fff',
          boxShadow: '0 1px 2px rgba(0,0,0,0.18), 0 0 0 0.5px rgba(0,0,0,0.05)',
          transition: 'left 160ms',
        }} />
      </span>
      <span>{label}</span>
    </label>
  );
}

// ─────────────────────────────────────────────────────────────
// Menu bar popover (system tray)
// ─────────────────────────────────────────────────────────────
function MenuBarPopover({ tunnels, onClose, onToggle, tokens, dark }) {
  const [q, setQ] = useStateE('');
  const filtered = q
    ? tunnels.filter(t => (t.name + t.host).toLowerCase().includes(q.toLowerCase()))
    : tunnels;

  const counts = {
    connected: tunnels.filter(t => t.state === 'connected').length,
    failed: tunnels.filter(t => t.state === 'failed').length,
    total: tunnels.length,
  };

  return (
    <div style={{
      position: 'absolute', top: 32, right: 20, zIndex: 200,
      width: 320,
      background: dark ? 'rgba(38,38,42,0.85)' : 'rgba(248,248,250,0.85)',
      backdropFilter: 'blur(40px) saturate(180%)',
      WebkitBackdropFilter: 'blur(40px) saturate(180%)',
      borderRadius: 12,
      boxShadow: '0 14px 40px rgba(0,0,0,0.28), 0 0 0 0.5px rgba(0,0,0,0.15)',
      animation: 'viaPopover 160ms cubic-bezier(.34,1.3,.64,1)',
      transformOrigin: 'top right',
      overflow: 'hidden',
    }}>
      {/* Header */}
      <div style={{
        padding: '10px 14px', display: 'flex', alignItems: 'center', gap: 8,
        borderBottom: `0.5px solid ${tokens.hairline}`,
      }}>
        <span style={{
          width: 18, height: 18, borderRadius: 5,
          background: tokens.accent,
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <IconE name="globe" size={11} color="#fff" />
        </span>
        <div style={{ flex: 1, fontSize: 13, fontWeight: 600, color: tokens.text }}>
          Viaduct
        </div>
        <div style={{ fontSize: 11, color: tokens.textSecondary }}>
          {counts.connected}/{counts.total} active
        </div>
        <button onClick={onClose} style={iconButtonE(tokens)} title="Close">
          <IconE name="x" size={11} color={tokens.textSecondary} />
        </button>
      </div>

      {/* Search */}
      <div style={{
        padding: '8px 10px', borderBottom: `0.5px solid ${tokens.hairline}`,
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 6, padding: '4px 8px',
          borderRadius: 6, background: tokens.inputBg, border: `0.5px solid ${tokens.inputBorder}`,
        }}>
          <IconE name="search" size={11} color={tokens.textTertiary} />
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search tunnels…" style={{
            flex: 1, border: 'none', outline: 'none', background: 'transparent',
            color: tokens.text, fontSize: 12,
          }} />
        </div>
      </div>

      {/* List */}
      <div style={{ maxHeight: 360, overflowY: 'auto' }}>
        {filtered.length === 0 ? (
          <div style={{ padding: '24px', textAlign: 'center', color: tokens.textTertiary, fontSize: 12 }}>
            No matches
          </div>
        ) : filtered.map((t, i) => {
          const isRunning = ['connected', 'connecting', 'reconnecting'].includes(t.state);
          return (
            <div key={t.id} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: '8px 12px',
              borderBottom: i === filtered.length - 1 ? 'none' : `0.5px solid ${tokens.hairline}`,
              cursor: 'default',
            }}
              onMouseEnter={(e) => e.currentTarget.style.background = tokens.surfaceHover}
              onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
            >
              <StatusDotE state={t.state} tokens={tokens} size={8} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 12.5, fontWeight: 600, color: tokens.text }}>{t.name}</div>
                <div style={{
                  fontSize: 10.5, color: tokens.textSecondary,
                  fontFamily: 'ui-monospace, SFMono-Regular, monospace',
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>{routeE(t)}</div>
              </div>
              <button onClick={() => onToggle(t.id)} style={{
                padding: '0 10px', height: 22, borderRadius: 11,
                border: 'none', cursor: 'default',
                background: isRunning ? `${tokens.danger}1f` : `${tokens.accent}1f`,
                color: isRunning ? tokens.danger : tokens.accent,
                fontSize: 11, fontWeight: 600,
              }}>{isRunning ? 'Stop' : 'Connect'}</button>
            </div>
          );
        })}
      </div>

      {/* Footer */}
      <div style={{
        padding: '8px 12px', display: 'flex', alignItems: 'center', gap: 10,
        borderTop: `0.5px solid ${tokens.hairline}`,
        fontSize: 11, color: tokens.textSecondary,
      }}>
        <button style={{
          background: 'transparent', border: 'none', color: tokens.accent,
          fontSize: 11.5, fontWeight: 500, cursor: 'default', padding: 0,
        }}>+ New Tunnel</button>
        <span style={{ flex: 1 }} />
        <span style={{ fontSize: 10.5, fontFamily: 'ui-monospace, monospace', color: tokens.textTertiary }}>⌘⇧V</span>
        <span>Quit</span>
      </div>
    </div>
  );
}

window.ViaductEditor = EditorSheet;
window.ViaductMenuBar = MenuBarPopover;
