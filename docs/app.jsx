// Viaduct — macOS SSH Tunnel Manager (redesign prototype)

const { useState, useEffect, useRef, useMemo, useCallback } = React;

// ─────────────────────────────────────────────────────────────
// Data — modeled on the Swift source
// ─────────────────────────────────────────────────────────────
const INITIAL_TUNNELS = [
  {
    id: 't1', name: 'Postgres — staging', type: 'local',
    host: 'bastion.staging.acme.dev', user: 'ops', port: 22,
    localPort: 5432, remoteHost: 'db-primary.internal', remotePort: 5432,
    bindAddress: '127.0.0.1',
    identityFile: '~/.ssh/acme_staging', authMethod: '1password_agent',
    autoConnect: true, agentForwarding: false,
    state: 'connected', uptimeSec: 4827, tags: ['staging', 'database'],
    events: [
      { kind: 'connected', message: 'Established channel', t: -120 },
      { kind: 'reconnecting', message: 'Network change detected', t: -3700 },
      { kind: 'disconnected', message: 'Sleep / wake cycle', t: -3805 },
      { kind: 'connected', message: 'Initial connect', t: -4827 },
    ],
  },
  {
    id: 't2', name: 'Grafana — prod', type: 'local',
    host: 'jump.prod.acme.io', user: 'sam', port: 22,
    localPort: 3000, remoteHost: 'grafana.svc.internal', remotePort: 3000,
    bindAddress: '127.0.0.1', proxyJump: 'jump.eu.acme.io',
    identityFile: '~/.ssh/id_ed25519', authMethod: 'system_agent',
    autoConnect: true, agentForwarding: true,
    state: 'connected', uptimeSec: 92143, tags: ['prod', 'monitoring'],
    events: [
      { kind: 'connected', message: 'Stable for 25h', t: -92143 },
    ],
  },
  {
    id: 't3', name: 'Redis — dev', type: 'local',
    host: 'dev.box.lan', user: 'sam', port: 22,
    localPort: 6379, remoteHost: 'localhost', remotePort: 6379,
    bindAddress: '127.0.0.1',
    identityFile: '~/.ssh/id_ed25519', authMethod: 'system_agent',
    autoConnect: false, agentForwarding: false,
    state: 'idle', uptimeSec: 0, tags: ['dev'],
    events: [],
  },
  {
    id: 't4', name: 'Webhook receiver', type: 'remote',
    host: 'edge-1.acme.io', user: 'webhook', port: 22,
    localPort: 8080, remoteHost: 'localhost', remotePort: 9090,
    bindAddress: '0.0.0.0',
    identityFile: '~/.ssh/webhook', authMethod: 'keychain_passphrase',
    autoConnect: false, agentForwarding: false,
    state: 'failed', uptimeSec: 0, tags: ['prod'],
    errorMessage: 'kex_exchange_identification: read: Connection reset',
    events: [
      { kind: 'error', message: 'Connection reset by peer', t: -45 },
      { kind: 'reconnecting', message: 'Attempt 3 of 5', t: -90 },
      { kind: 'reconnecting', message: 'Attempt 2 of 5', t: -150 },
      { kind: 'reconnecting', message: 'Attempt 1 of 5', t: -210 },
    ],
  },
  {
    id: 't5', name: 'SOCKS — coffee shop', type: 'dynamic',
    host: 'home.sam.dev', user: 'sam', port: 22,
    localPort: 1080, bindAddress: '127.0.0.1',
    identityFile: '~/.ssh/id_ed25519', authMethod: 'system_agent',
    autoConnect: false, agentForwarding: false,
    state: 'idle', uptimeSec: 0, tags: ['personal'],
    events: [],
  },
  {
    id: 't6', name: 'Kafka broker', type: 'local',
    host: 'kafka.eu.acme.io', user: 'data', port: 2222,
    localPort: 9092, remoteHost: 'b-1.kafka.internal', remotePort: 9092,
    bindAddress: '127.0.0.1',
    identityFile: '~/.ssh/data_ed25519', authMethod: '1password_agent',
    autoConnect: false, agentForwarding: false,
    state: 'connecting', uptimeSec: 0, tags: ['prod', 'data'],
    events: [
      { kind: 'reconnecting', message: 'Resolving host…', t: -2 },
    ],
  },
];

const TAGS = [
  { id: 'prod', name: 'Production', color: '#FF453A', count: 3 },
  { id: 'staging', name: 'Staging', color: '#FF9F0A', count: 1 },
  { id: 'dev', name: 'Development', color: '#30D158', count: 1 },
  { id: 'database', name: 'Databases', color: '#0A84FF', count: 1 },
  { id: 'monitoring', name: 'Monitoring', color: '#BF5AF2', count: 1 },
  { id: 'data', name: 'Data', color: '#64D2FF', count: 1 },
  { id: 'personal', name: 'Personal', color: '#5E5CE6', count: 1 },
];

// ─────────────────────────────────────────────────────────────
// Utilities
// ─────────────────────────────────────────────────────────────
function formatUptime(sec) {
  if (sec < 60) return `${sec}s`;
  if (sec < 3600) return `${Math.floor(sec / 60)}m`;
  if (sec < 86400) return `${Math.floor(sec / 3600)}h ${Math.floor((sec % 3600) / 60)}m`;
  return `${Math.floor(sec / 86400)}d ${Math.floor((sec % 86400) / 3600)}h`;
}
function relativeTime(secAgo) {
  const s = Math.abs(secAgo);
  if (s < 60) return `${s}s ago`;
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  return `${Math.floor(s / 86400)}d ago`;
}
function routeDescription(t) {
  const bind = t.bindAddress || '127.0.0.1';
  if (t.type === 'local')   return `${bind}:${t.localPort}  →  ${t.remoteHost}:${t.remotePort}`;
  if (t.type === 'remote')  return `${t.host}:${t.remotePort}  →  ${t.remoteHost || 'localhost'}:${t.localPort}`;
  if (t.type === 'dynamic') return `SOCKS  ${bind}:${t.localPort}`;
}
function endpointDescription(t) {
  const bind = t.bindAddress || '127.0.0.1';
  if (t.type === 'remote') return `${t.host}:${t.remotePort}`;
  return `${bind}:${t.localPort}`;
}
function effectiveCommand(t) {
  const args = ['ssh'];
  args.push('-N');
  if (t.type === 'local')   args.push('-L', `${t.bindAddress || '127.0.0.1'}:${t.localPort}:${t.remoteHost}:${t.remotePort}`);
  if (t.type === 'remote')  args.push('-R', `${t.remotePort}:${t.remoteHost || 'localhost'}:${t.localPort}`);
  if (t.type === 'dynamic') args.push('-D', `${t.bindAddress || '127.0.0.1'}:${t.localPort}`);
  if (t.port !== 22) args.push('-p', String(t.port));
  if (t.identityFile) args.push('-i', t.identityFile);
  if (t.proxyJump) args.push('-J', t.proxyJump);
  if (t.agentForwarding) args.push('-A');
  args.push(t.user ? `${t.user}@${t.host}` : t.host);
  return args.join(' ');
}

// ─────────────────────────────────────────────────────────────
// Theme tokens (driven by tweaks)
// ─────────────────────────────────────────────────────────────
const ACCENTS = {
  blue:    { name: 'Blue',    hex: '#0A84FF', glow: 'rgba(10,132,255,0.35)' },
  purple:  { name: 'Purple',  hex: '#BF5AF2', glow: 'rgba(191,90,242,0.35)' },
  pink:    { name: 'Pink',    hex: '#FF375F', glow: 'rgba(255,55,95,0.35)' },
  orange:  { name: 'Orange',  hex: '#FF9F0A', glow: 'rgba(255,159,10,0.35)' },
  green:   { name: 'Green',   hex: '#30D158', glow: 'rgba(48,209,88,0.35)' },
  graphite:{ name: 'Graphite',hex: '#8E8E93', glow: 'rgba(142,142,147,0.35)' },
};

function makeTokens(dark, accentKey) {
  const accent = ACCENTS[accentKey] || ACCENTS.blue;
  if (dark) return {
    accent: accent.hex, accentGlow: accent.glow,
    bg: '#1e1e1e',
    sidebarBg: 'rgba(36, 36, 38, 0.72)',
    sidebarTint: 'linear-gradient(180deg, rgba(60,60,65,0.55), rgba(38,38,42,0.55))',
    listBg: '#1f1f21',
    contentBg: '#232325',
    surface: 'rgba(255,255,255,0.04)',
    surfaceHover: 'rgba(255,255,255,0.06)',
    surfaceActive: 'rgba(255,255,255,0.09)',
    border: 'rgba(255,255,255,0.08)',
    hairline: 'rgba(255,255,255,0.06)',
    text: 'rgba(255,255,255,0.92)',
    textSecondary: 'rgba(235,235,245,0.6)',
    textTertiary: 'rgba(235,235,245,0.3)',
    selectionBg: accent.hex,
    selectionFg: '#fff',
    titlebarBg: 'rgba(40,40,42,0.8)',
    chipBg: 'rgba(255,255,255,0.08)',
    success: '#30D158', warn: '#FF9F0A', danger: '#FF453A', muted: '#8E8E93',
    shadow: '0 24px 60px rgba(0,0,0,0.55), 0 0 0 0.5px rgba(255,255,255,0.08)',
    inputBg: 'rgba(255,255,255,0.06)',
    inputBorder: 'rgba(255,255,255,0.1)',
  };
  return {
    accent: accent.hex, accentGlow: accent.glow,
    bg: '#ECECEC',
    sidebarBg: 'rgba(246, 246, 248, 0.72)',
    sidebarTint: 'linear-gradient(180deg, rgba(232,236,244,0.78), rgba(220,226,238,0.78))',
    listBg: '#F6F6F8',
    contentBg: '#FFFFFF',
    surface: 'rgba(0,0,0,0.025)',
    surfaceHover: 'rgba(0,0,0,0.045)',
    surfaceActive: 'rgba(0,0,0,0.075)',
    border: 'rgba(0,0,0,0.08)',
    hairline: 'rgba(0,0,0,0.06)',
    text: 'rgba(0,0,0,0.88)',
    textSecondary: 'rgba(0,0,0,0.55)',
    textTertiary: 'rgba(0,0,0,0.32)',
    selectionBg: accent.hex,
    selectionFg: '#fff',
    titlebarBg: 'rgba(246,246,248,0.85)',
    chipBg: 'rgba(0,0,0,0.05)',
    success: '#28B642', warn: '#E48900', danger: '#E5413B', muted: '#8E8E93',
    shadow: '0 30px 60px rgba(0,0,0,0.22), 0 0 0 0.5px rgba(0,0,0,0.1)',
    inputBg: 'rgba(0,0,0,0.04)',
    inputBorder: 'rgba(0,0,0,0.08)',
  };
}

// ─────────────────────────────────────────────────────────────
// Icons (SF-symbol-style, hand-tuned, simple)
// ─────────────────────────────────────────────────────────────
const Icon = ({ name, size = 14, color = 'currentColor', strokeWidth = 1.6 }) => {
  const p = { width: size, height: size, viewBox: '0 0 16 16', fill: 'none', stroke: color, strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (name) {
    case 'plus':       return <svg {...p}><path d="M8 3v10M3 8h10"/></svg>;
    case 'search':     return <svg {...p}><circle cx="7" cy="7" r="4.2"/><path d="M10 10l3 3"/></svg>;
    case 'sidebar':    return <svg {...p}><rect x="2" y="3" width="12" height="10" rx="2"/><path d="M6 3v10"/></svg>;
    case 'play':       return <svg {...p} fill={color} stroke="none"><path d="M4.5 3.2v9.6c0 .6.65.97 1.18.66l7.45-4.8a.78.78 0 000-1.32L5.68 2.54A.78.78 0 004.5 3.2z"/></svg>;
    case 'stop':       return <svg {...p} fill={color} stroke="none"><rect x="4" y="4" width="8" height="8" rx="1.2"/></svg>;
    case 'refresh':    return <svg {...p}><path d="M13 8a5 5 0 11-1.46-3.54M13 2.5V5H10.5"/></svg>;
    case 'pencil':     return <svg {...p}><path d="M11.5 2.5l2 2L5 13H3v-2l8.5-8.5z"/></svg>;
    case 'trash':      return <svg {...p}><path d="M3 4.5h10M6 4.5V3a1 1 0 011-1h2a1 1 0 011 1v1.5M5 4.5l.7 8a1 1 0 001 .9h2.6a1 1 0 001-.9l.7-8"/></svg>;
    case 'terminal':   return <svg {...p}><rect x="2" y="3" width="12" height="10" rx="1.5"/><path d="M5 7l2 1.5L5 10M8.5 10.5h3"/></svg>;
    case 'copy':       return <svg {...p}><rect x="3.5" y="3.5" width="7" height="7" rx="1.2"/><path d="M6 3.5V2.2A1.2 1.2 0 017.2 1h5.6A1.2 1.2 0 0114 2.2v5.6A1.2 1.2 0 0112.8 9H11.5"/></svg>;
    case 'check':      return <svg {...p}><path d="M3.5 8.5l3 3 6-7"/></svg>;
    case 'x':          return <svg {...p}><path d="M4 4l8 8M12 4l-8 8"/></svg>;
    case 'chevron':    return <svg {...p}><path d="M6 4l4 4-4 4"/></svg>;
    case 'chevron-d':  return <svg {...p}><path d="M4 6l4 4 4-4"/></svg>;
    case 'globe':      return <svg {...p}><circle cx="8" cy="8" r="5.5"/><path d="M2.5 8h11M8 2.5c2 2 2 9 0 11M8 2.5c-2 2-2 9 0 11"/></svg>;
    case 'all':        return <svg {...p}><rect x="2" y="3" width="12" height="3" rx="1"/><rect x="2" y="7" width="12" height="3" rx="1"/><rect x="2" y="11" width="12" height="2" rx="1"/></svg>;
    case 'bolt':       return <svg {...p} fill={color} stroke="none"><path d="M8.8 1l-5 8.2h3.4L6.2 15l5-8.2H7.8z"/></svg>;
    case 'warn':       return <svg {...p}><path d="M8 2l6.5 11h-13L8 2z"/><path d="M8 7v3M8 11.5v.01"/></svg>;
    case 'circle':     return <svg {...p}><circle cx="8" cy="8" r="6"/></svg>;
    case 'tag':        return <svg {...p}><path d="M2.5 8.5L7.5 3.5h5v5l-5 5-5-5z"/><circle cx="10" cy="6" r=".8" fill={color}/></svg>;
    case 'key':        return <svg {...p}><circle cx="5.5" cy="10.5" r="2.5"/><path d="M7.5 8.5l5-5M10.5 5.5l1.5 1.5M9 7l1.5 1.5"/></svg>;
    case 'cmd':        return <svg {...p}><path d="M5 5a1.5 1.5 0 11-1.5 1.5V9.5A1.5 1.5 0 115 11h6a1.5 1.5 0 111.5-1.5V6.5A1.5 1.5 0 1111 5H5z"/></svg>;
    case 'lock':       return <svg {...p}><rect x="3.5" y="7" width="9" height="6.5" rx="1.5"/><path d="M5.5 7V5a2.5 2.5 0 015 0v2"/></svg>;
    case 'gear':       return <svg {...p}><circle cx="8" cy="8" r="2"/><path d="M8 1.5v2M8 12.5v2M14.5 8h-2M3.5 8h-2M12.6 3.4l-1.4 1.4M4.8 11.2l-1.4 1.4M12.6 12.6l-1.4-1.4M4.8 4.8L3.4 3.4"/></svg>;
    case 'kebab':      return <svg {...p}><circle cx="8" cy="3.5" r=".9" fill={color} stroke="none"/><circle cx="8" cy="8" r=".9" fill={color} stroke="none"/><circle cx="8" cy="12.5" r=".9" fill={color} stroke="none"/></svg>;
    case 'arrowRight': return <svg {...p}><path d="M3 8h10M9 4l4 4-4 4"/></svg>;
    case 'sleep':      return <svg {...p}><path d="M13 9.5a5 5 0 11-6.5-6.5A5.2 5.2 0 0013 9.5z"/></svg>;
    default: return null;
  }
};

window.ViaductData = { INITIAL_TUNNELS, TAGS };
window.ViaductUtils = { formatUptime, relativeTime, routeDescription, endpointDescription, effectiveCommand, makeTokens, ACCENTS, Icon };
