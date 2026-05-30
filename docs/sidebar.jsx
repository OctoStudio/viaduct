// Viaduct — Main app components

const { useState: useStateV, useEffect: useEffectV, useRef: useRefV, useMemo: useMemoV } = React;
const { INITIAL_TUNNELS, TAGS } = window.ViaductData;
const { formatUptime, relativeTime, routeDescription, endpointDescription, effectiveCommand, makeTokens, ACCENTS, Icon } = window.ViaductUtils;

// ─────────────────────────────────────────────────────────────
// Status dot
// ─────────────────────────────────────────────────────────────
function StatusDot({ state, size = 8, tokens }) {
  const colorMap = {
    connected:    tokens.success,
    connecting:   tokens.warn,
    reconnecting: tokens.warn,
    failed:       tokens.danger,
    idle:         tokens.muted,
    stopped:      tokens.muted,
  };
  const c = colorMap[state] || tokens.muted;
  const pulse = state === 'connecting' || state === 'reconnecting';
  return (
    <span style={{
      display: 'inline-flex', position: 'relative',
      width: size, height: size, flexShrink: 0,
    }}>
      <span style={{
        width: size, height: size, borderRadius: '50%', background: c,
        boxShadow: state === 'connected' ? `0 0 0 1.5px ${c}30` : 'none',
      }} />
      {pulse && (
        <span style={{
          position: 'absolute', inset: -3,
          borderRadius: '50%', border: `1.5px solid ${c}`,
          animation: 'viaPulse 1.4s ease-out infinite',
        }} />
      )}
    </span>
  );
}

// ─────────────────────────────────────────────────────────────
// Type chip
// ─────────────────────────────────────────────────────────────
function TypeChip({ type, tokens }) {
  const label = { local: 'Local', remote: 'Remote', dynamic: 'SOCKS' }[type];
  return (
    <span style={{
      fontSize: 10, fontWeight: 600, letterSpacing: 0.3,
      padding: '1.5px 6px', borderRadius: 4,
      background: tokens.chipBg, color: tokens.textSecondary,
      textTransform: 'uppercase', lineHeight: 1.4,
    }}>{label}</span>
  );
}

// ─────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────
function Sidebar({ selected, onSelect, tunnels, tokens, accentKey, dark, onMenuBar, density }) {
  const counts = useMemoV(() => ({
    all: tunnels.length,
    connected: tunnels.filter(t => t.state === 'connected').length,
    errors: tunnels.filter(t => t.state === 'failed').length,
  }), [tunnels]);

  const Item = ({ id, icon, label, count, color }) => {
    const isSel = selected === id;
    return (
      <div
        onClick={() => onSelect(id)}
        style={{
          display: 'flex', alignItems: 'center', gap: 8,
          padding: density === 'compact' ? '3px 8px 3px 10px' : '5px 8px 5px 10px',
          margin: '1px 8px', borderRadius: 6, cursor: 'default',
          background: isSel ? tokens.selectionBg : 'transparent',
          color: isSel ? tokens.selectionFg : tokens.text,
          fontSize: 13, fontWeight: 500,
          transition: 'background 80ms',
        }}
        onMouseEnter={(e) => { if (!isSel) e.currentTarget.style.background = tokens.surfaceHover; }}
        onMouseLeave={(e) => { if (!isSel) e.currentTarget.style.background = 'transparent'; }}
      >
        <span style={{
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
          width: 16, color: isSel ? '#fff' : (color || tokens.textSecondary),
        }}>{icon}</span>
        <span style={{ flex: 1 }}>{label}</span>
        {typeof count === 'number' && (
          <span style={{
            fontSize: 11, fontWeight: 500,
            color: isSel ? 'rgba(255,255,255,0.85)' : tokens.textTertiary,
            fontVariantNumeric: 'tabular-nums',
          }}>{count}</span>
        )}
      </div>
    );
  };

  const Header = ({ children }) => (
    <div style={{
      padding: '14px 18px 4px', fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
      color: tokens.textTertiary, textTransform: 'uppercase',
    }}>{children}</div>
  );

  return (
    <aside style={{
      width: 200, flexShrink: 0, position: 'relative',
      background: tokens.sidebarBg,
      backdropFilter: 'blur(40px) saturate(180%)',
      WebkitBackdropFilter: 'blur(40px) saturate(180%)',
      borderRight: `0.5px solid ${tokens.border}`,
      display: 'flex', flexDirection: 'column',
    }}>
      {/* tinted overlay for that subtle macOS sidebar tone */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        background: tokens.sidebarTint,
        opacity: dark ? 0.4 : 0.55,
      }} />

      {/* traffic lights + title */}
      <div style={{
        position: 'relative', display: 'flex', alignItems: 'center',
        height: 42, padding: '0 12px', gap: 10, flexShrink: 0,
      }}>
        <div style={{ display: 'flex', gap: 8 }}>
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#FF5F57', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.18)' }} />
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#FEBC2E', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.18)' }} />
          <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#28C840', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.18)' }} />
        </div>
      </div>

      {/* scrollable content */}
      <div style={{ position: 'relative', flex: 1, overflowY: 'auto', paddingBottom: 8 }}>
        <Header>Smart Groups</Header>
        <Item id="all" label="All Tunnels" count={counts.all}
          icon={<Icon name="all" size={13} />} color={tokens.accent} />
        <Item id="connected" label="Connected" count={counts.connected}
          icon={<StatusDot state="connected" tokens={tokens} size={8} />} />
        <Item id="errors" label="Errors" count={counts.errors}
          icon={<StatusDot state="failed" tokens={tokens} size={8} />} />
        <Item id="autoconnect" label="Auto-Connect"
          icon={<Icon name="bolt" size={12} color={tokens.warn} />} />

        <Header>Tags</Header>
        {TAGS.map(tag => (
          <Item key={tag.id} id={`tag:${tag.id}`} label={tag.name} count={tag.count}
            icon={<span style={{
              width: 10, height: 10, borderRadius: '50%',
              background: tag.color, display: 'inline-block',
            }} />} />
        ))}
      </div>

      {/* footer */}
      <div style={{
        position: 'relative', padding: '6px 10px',
        borderTop: `0.5px solid ${tokens.hairline}`,
        display: 'flex', alignItems: 'center', gap: 6,
      }}>
        <button onClick={onMenuBar} style={iconButton(tokens)} title="Menu bar preview">
          <Icon name="globe" size={13} color={tokens.textSecondary} />
        </button>
        <span style={{ fontSize: 11, color: tokens.textTertiary, flex: 1 }}>
          {counts.connected} of {counts.all} active
        </span>
      </div>
    </aside>
  );
}

function iconButton(tokens, active) {
  return {
    width: 24, height: 22, display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    background: active ? tokens.surfaceActive : 'transparent',
    border: 'none', borderRadius: 5, padding: 0, cursor: 'default',
    color: tokens.text,
  };
}

window.ViaductSidebar = Sidebar;
window.ViaductBits = { StatusDot, TypeChip, iconButton };
