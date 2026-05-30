// Viaduct — Root app

const { useState: useStateA, useEffect: useEffectA, useMemo: useMemoA, useRef: useRefA } = React;
const { INITIAL_TUNNELS: INITIAL, TAGS: TAGS_A } = window.ViaductData;
const { makeTokens: makeTok, ACCENTS: ACC, Icon: IconA } = window.ViaductUtils;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "blue",
  "appearance": "light",
  "density": "comfortable",
  "wallpaper": "warm"
}/*EDITMODE-END*/;

const WALLPAPERS = {
  warm:    'radial-gradient(ellipse at 18% 22%, #FFC79A 0%, transparent 45%), radial-gradient(ellipse at 88% 78%, #FFA28A 0%, transparent 45%), linear-gradient(135deg, #F2C0DA 0%, #FFD7B8 50%, #F8E1B0 100%)',
  cool:    'radial-gradient(ellipse at 18% 22%, #95C5FF 0%, transparent 45%), radial-gradient(ellipse at 85% 80%, #A48BFF 0%, transparent 45%), linear-gradient(135deg, #79A7FF 0%, #B9A6FF 60%, #DCC4F2 100%)',
  graphite:'radial-gradient(ellipse at 20% 24%, #4a4a52 0%, transparent 45%), radial-gradient(ellipse at 82% 78%, #2b2b30 0%, transparent 50%), linear-gradient(135deg, #1f1f23 0%, #303036 100%)',
  monterey:'radial-gradient(ellipse at 30% 30%, #FF8FB6 0%, transparent 50%), radial-gradient(ellipse at 80% 75%, #6E94FF 0%, transparent 50%), linear-gradient(135deg, #B57AE6 0%, #6E94FF 100%)',
};

function App() {
  const [tunnels, setTunnels] = useStateA(INITIAL);
  const [selectedSidebarItem, setSelectedSidebarItem] = useStateA('all');
  const [selectedId, setSelectedId] = useStateA('t1');
  const [searchText, setSearchText] = useStateA('');
  const [editorTunnel, setEditorTunnel] = useStateA(null);
  const [editorOpen, setEditorOpen] = useStateA(false);
  const [menubarOpen, setMenubarOpen] = useStateA(false);
  const [tweaks, setTweak] = window.useTweaks(TWEAK_DEFAULTS);

  // Uptime tick
  useEffectA(() => {
    const id = setInterval(() => {
      setTunnels(prev => prev.map(t => {
        if (t.state === 'connected') return { ...t, uptimeSec: t.uptimeSec + 1 };
        if (t.state === 'connecting') return t;
        return t;
      }));
    }, 1000);
    return () => clearInterval(id);
  }, []);

  // Resolve connecting state -> connected after ~1.8s
  useEffectA(() => {
    const t = tunnels.find(x => x.state === 'connecting');
    if (!t) return;
    const id = setTimeout(() => {
      setTunnels(prev => prev.map(x => x.id === t.id
        ? { ...x, state: 'connected', uptimeSec: 1,
            events: [{ kind: 'connected', message: 'Channel established', t: -1 }, ...x.events] }
        : x));
    }, 1800 + Math.random() * 800);
    return () => clearTimeout(id);
  }, [tunnels]);

  // Filtered tunnels
  const filtered = useMemoA(() => {
    let arr = tunnels;
    if (selectedSidebarItem === 'connected') arr = arr.filter(t => t.state === 'connected');
    else if (selectedSidebarItem === 'errors') arr = arr.filter(t => t.state === 'failed');
    else if (selectedSidebarItem === 'autoconnect') arr = arr.filter(t => t.autoConnect);
    else if (selectedSidebarItem.startsWith('tag:')) {
      const id = selectedSidebarItem.slice(4);
      arr = arr.filter(t => t.tags && t.tags.includes(id));
    }
    if (searchText) {
      const q = searchText.toLowerCase();
      arr = arr.filter(t =>
        t.name.toLowerCase().includes(q)
        || t.host.toLowerCase().includes(q)
        || (t.remoteHost || '').toLowerCase().includes(q));
    }
    return arr;
  }, [tunnels, selectedSidebarItem, searchText]);

  const selected = useMemoA(
    () => filtered.find(t => t.id === selectedId) || tunnels.find(t => t.id === selectedId),
    [filtered, tunnels, selectedId]
  );

  // Auto-pick first tunnel when current vanishes from filter
  useEffectA(() => {
    if (!filtered.find(t => t.id === selectedId) && filtered.length > 0) {
      setSelectedId(filtered[0].id);
    }
  }, [filtered, selectedId]);

  const toggleTunnel = (id) => {
    setTunnels(prev => prev.map(t => {
      if (t.id !== id) return t;
      const isRunning = ['connected', 'connecting', 'reconnecting'].includes(t.state);
      if (isRunning) return {
        ...t, state: 'stopped', uptimeSec: 0,
        events: [{ kind: 'disconnected', message: 'Stopped by user', t: 0 }, ...t.events],
      };
      return { ...t, state: 'connecting', uptimeSec: 0 };
    }));
  };

  const restartTunnel = (id) => {
    setTunnels(prev => prev.map(t => {
      if (t.id !== id) return t;
      return { ...t, state: 'connecting', uptimeSec: 0,
        events: [{ kind: 'reconnecting', message: 'Manual restart', t: 0 }, ...t.events] };
    }));
  };

  const deleteTunnel = (id) => {
    setTunnels(prev => prev.filter(t => t.id !== id));
  };

  const saveTunnel = (t) => {
    setTunnels(prev => {
      const exists = prev.find(x => x.id === t.id);
      if (exists) return prev.map(x => x.id === t.id ? { ...x, ...t } : x);
      return [...prev, { ...t, state: 'idle', uptimeSec: 0, events: [] }];
    });
    setSelectedId(t.id);
    setEditorOpen(false);
  };

  // Keyboard
  useEffectA(() => {
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'n') {
        e.preventDefault();
        setEditorTunnel(null); setEditorOpen(true);
      }
      if (e.key === 'Escape') { setEditorOpen(false); setMenubarOpen(false); }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  const dark = tweaks.appearance === 'dark';
  const tokens = useMemoA(() => makeTok(dark, tweaks.accent), [dark, tweaks.accent]);

  // Apply page background (wallpaper) via root inline style
  useEffectA(() => {
    document.body.style.background = WALLPAPERS[tweaks.wallpaper] || WALLPAPERS.warm;
    document.body.style.backgroundAttachment = 'fixed';
    document.body.style.backgroundSize = 'cover';
  }, [tweaks.wallpaper]);

  return (
    <div style={{
      width: '100vw', height: '100vh', display: 'flex',
      alignItems: 'center', justifyContent: 'center',
      padding: 28, boxSizing: 'border-box',
      position: 'relative',
    }}>
      {/* Mock macOS menu bar at very top */}
      <FakeMenuBar tokens={tokens} dark={dark} accent={tokens.accent}
        connected={tunnels.filter(t => t.state === 'connected').length}
        total={tunnels.length}
        hasError={tunnels.some(t => t.state === 'failed')}
        onClickIcon={() => setMenubarOpen(o => !o)}
      />

      {/* Window */}
      <div style={{
        width: 'min(1140px, 100%)', height: 'min(720px, calc(100% - 56px))',
        background: tokens.bg, borderRadius: 12, overflow: 'hidden',
        display: 'flex', position: 'relative',
        boxShadow: tokens.shadow,
        marginTop: 28,
        color: tokens.text,
      }}>
        <window.ViaductSidebar
          tunnels={tunnels}
          selected={selectedSidebarItem}
          onSelect={setSelectedSidebarItem}
          tokens={tokens}
          accentKey={tweaks.accent}
          dark={dark}
          density={tweaks.density}
          onMenuBar={() => setMenubarOpen(o => !o)}
        />
        <window.ViaductList
          tunnels={filtered}
          selectedId={selectedId}
          onSelect={setSelectedId}
          onToggle={toggleTunnel}
          onNew={() => { setEditorTunnel(null); setEditorOpen(true); }}
          searchText={searchText}
          onSearchText={setSearchText}
          tokens={tokens}
          density={tweaks.density}
        />
        <window.ViaductDetail
          tunnel={selected}
          tokens={tokens}
          onToggle={() => selected && toggleTunnel(selected.id)}
          onRestart={() => selected && restartTunnel(selected.id)}
          onEdit={() => { setEditorTunnel(selected); setEditorOpen(true); }}
          onDelete={() => selected && deleteTunnel(selected.id)}
        />

        {editorOpen && (
          <window.ViaductEditor
            tunnel={editorTunnel}
            onClose={() => setEditorOpen(false)}
            onSave={saveTunnel}
            tokens={tokens}
            dark={dark}
          />
        )}
      </div>

      {menubarOpen && (
        <window.ViaductMenuBar
          tunnels={tunnels}
          onClose={() => setMenubarOpen(false)}
          onToggle={toggleTunnel}
          tokens={tokens}
          dark={dark}
        />
      )}

      {tunnels.find(t => t.state === 'failed') && null}
      {/* Tweaks panel — host protocol handled internally. Always mounted. */}
      <window.TweaksPanel title="Tweaks">
        <window.TweakSection title="Appearance">
          <window.TweakRadio label="Mode" value={tweaks.appearance}
            options={[{value: 'light', label: 'Light'}, {value: 'dark', label: 'Dark'}]}
            onChange={v => setTweak('appearance', v)} />
          <window.TweakColor label="Accent"
            value={ACC[tweaks.accent].hex}
            options={Object.values(ACC).map(a => a.hex)}
            onChange={hex => {
              const k = Object.keys(ACC).find(k => ACC[k].hex === hex) || 'blue';
              setTweak('accent', k);
            }}
          />
          <window.TweakRadio label="Density" value={tweaks.density}
            options={[{value: 'comfortable', label: 'Comfortable'}, {value: 'compact', label: 'Compact'}]}
            onChange={v => setTweak('density', v)} />
          <window.TweakSelect label="Wallpaper" value={tweaks.wallpaper}
            options={[
              { value: 'warm', label: 'Warm Sonoma' },
              { value: 'cool', label: 'Cool Sequoia' },
              { value: 'monterey', label: 'Monterey Bloom' },
              { value: 'graphite', label: 'Graphite' },
            ]}
            onChange={v => setTweak('wallpaper', v)} />
        </window.TweakSection>
        <window.TweakSection title="Open">
          <window.TweakButton label="Show menu bar tray" onClick={() => setMenubarOpen(true)} />
          <window.TweakButton label="New tunnel sheet" onClick={() => { setEditorTunnel(null); setEditorOpen(true); }} />
        </window.TweakSection>
      </window.TweaksPanel>
    </div>
  );
}

function FakeMenuBar({ tokens, dark, accent, connected, total, hasError, onClickIcon }) {
  const statusColor = hasError ? tokens.danger : (connected > 0 ? tokens.success : tokens.muted);
  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, right: 0, height: 28,
      background: dark ? 'rgba(0,0,0,0.45)' : 'rgba(255,255,255,0.32)',
      backdropFilter: 'blur(40px) saturate(180%)',
      WebkitBackdropFilter: 'blur(40px) saturate(180%)',
      display: 'flex', alignItems: 'center', padding: '0 14px', gap: 18,
      fontSize: 12.5, color: dark ? '#fff' : '#1a1a1a',
      zIndex: 50, borderBottom: dark ? '0.5px solid rgba(255,255,255,0.08)' : '0.5px solid rgba(0,0,0,0.06)',
    }}>
      <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontWeight: 500 }}>
        <svg width="14" height="14" viewBox="0 0 384 512" fill="currentColor" style={{ marginTop: -2 }}>
          <path d="M318.7 268.7c-.2-36.7 16.4-64.4 50-84.8-18.8-26.9-47.2-41.7-84.7-44.6-35.5-2.8-74.3 20.7-88.5 20.7-15 0-49.4-19.7-76.4-19.7C63.3 141.2 4 184.8 4 273.5q0 39.3 14.4 81.2c12.8 36.7 59 126.7 107.2 125.2 25.2-.6 43-17.9 75.8-17.9 31.8 0 48.3 17.9 76.4 17.9 48.6-.7 90.4-82.5 102.6-119.3-65.2-30.7-61.7-90-61.7-91.9zm-56.6-164.2c27.3-32.4 24.8-61.9 24-72.5-24.1 1.4-52 16.4-67.9 34.9-17.5 19.8-27.8 44.3-25.6 71.9 26.1 2 49.9-11.4 69.5-34.3z"/>
        </svg>
        <span style={{ fontWeight: 600 }}>Viaduct</span>
        <span style={{ marginLeft: 2 }}>File</span>
        <span>Edit</span>
        <span>View</span>
        <span>Tunnel</span>
        <span>Window</span>
        <span>Help</span>
      </span>
      <span style={{ flex: 1 }} />
      <button onClick={onClickIcon} title="Open menu bar tray" style={{
        background: 'transparent', border: 'none', color: 'inherit',
        display: 'inline-flex', alignItems: 'center', gap: 5, cursor: 'default',
        padding: '2px 6px', borderRadius: 4, fontSize: 11,
      }}>
        <span style={{
          width: 8, height: 8, borderRadius: '50%', background: statusColor,
          boxShadow: connected > 0 ? `0 0 0 1.5px ${statusColor}30` : 'none',
        }} />
        <svg width="14" height="14" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.6">
          <path d="M2 5h12M2 8h12M2 11h12" strokeLinecap="round"/>
        </svg>
      </button>
      <span style={{ fontVariantNumeric: 'tabular-nums', opacity: 0.7 }}>
        {new Date().toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}
      </span>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
