// Viaduct — Tunnel list (middle column)

const { useState: useStateL, useMemo: useMemoL } = React;
const { formatUptime: fmtUptime, routeDescription: routeDesc } = window.ViaductUtils;
const { Icon: IconL } = window.ViaductUtils;
const { StatusDot: StatusDotL, TypeChip: TypeChipL, iconButton: iconButtonL } = window.ViaductBits;

function TunnelList({
  tunnels, selectedId, onSelect, onToggle, onNew,
  searchText, onSearchText,
  tokens, density,
}) {
  const [sort, setSort] = useStateL('name');
  const [sortMenuOpen, setSortMenuOpen] = useStateL(false);

  const sorted = useMemoL(() => {
    const arr = [...tunnels];
    const rank = (t) => ({ connected: 0, connecting: 1, reconnecting: 2, failed: 3, idle: 4, stopped: 5 }[t.state] ?? 6);
    arr.sort((a, b) => {
      if (sort === 'host') return a.host.localeCompare(b.host);
      if (sort === 'status') return rank(a) - rank(b);
      return a.name.localeCompare(b.name);
    });
    return arr;
  }, [tunnels, sort]);

  const rowPadY = density === 'compact' ? 7 : 10;

  return (
    <section style={{
      width: 320, flexShrink: 0, display: 'flex', flexDirection: 'column',
      background: tokens.listBg,
      borderRight: `0.5px solid ${tokens.border}`,
    }}>
      {/* Toolbar: search + actions */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 8,
        padding: '8px 10px', height: 42, flexShrink: 0,
        borderBottom: `0.5px solid ${tokens.hairline}`,
        background: tokens.titlebarBg,
        backdropFilter: 'blur(20px)',
        WebkitBackdropFilter: 'blur(20px)',
      }}>
        <div style={{
          flex: 1, display: 'flex', alignItems: 'center', gap: 6,
          padding: '4px 8px', borderRadius: 6,
          background: tokens.inputBg, border: `0.5px solid ${tokens.inputBorder}`,
        }}>
          <IconL name="search" size={12} color={tokens.textTertiary} />
          <input
            value={searchText}
            onChange={(e) => onSearchText(e.target.value)}
            placeholder="Search"
            style={{
              flex: 1, border: 'none', outline: 'none', background: 'transparent',
              fontSize: 12, color: tokens.text, padding: 0,
              fontFamily: 'inherit',
            }}
          />
          {searchText && (
            <button onClick={() => onSearchText('')} style={{
              border: 'none', background: 'transparent', padding: 0, cursor: 'default',
              color: tokens.textTertiary, display: 'flex',
            }}>
              <IconL name="x" size={11} />
            </button>
          )}
        </div>
        <div style={{ position: 'relative' }}>
          <button onClick={() => setSortMenuOpen(o => !o)} style={{
            ...iconButtonL(tokens), width: 28, height: 24,
            fontSize: 11, color: tokens.textSecondary, gap: 2,
          }}>
            <span>{sort[0].toUpperCase() + sort.slice(1)}</span>
            <IconL name="chevron-d" size={9} color={tokens.textTertiary} />
          </button>
          {sortMenuOpen && (
            <div onMouseLeave={() => setSortMenuOpen(false)} style={{
              position: 'absolute', top: 28, right: 0, zIndex: 30,
              background: tokens.contentBg, borderRadius: 8,
              boxShadow: tokens.shadow,
              border: `0.5px solid ${tokens.border}`,
              padding: 4, minWidth: 120,
            }}>
              {['name', 'host', 'status'].map(opt => (
                <div key={opt} onClick={() => { setSort(opt); setSortMenuOpen(false); }} style={{
                  padding: '5px 10px', borderRadius: 4, fontSize: 12,
                  display: 'flex', alignItems: 'center', gap: 6,
                  color: tokens.text, cursor: 'default',
                }}
                  onMouseEnter={(e) => e.currentTarget.style.background = tokens.surfaceHover}
                  onMouseLeave={(e) => e.currentTarget.style.background = 'transparent'}
                >
                  <span style={{ width: 12, color: tokens.accent }}>
                    {sort === opt && <IconL name="check" size={11} />}
                  </span>
                  <span>{opt[0].toUpperCase() + opt.slice(1)}</span>
                </div>
              ))}
            </div>
          )}
        </div>
        <button onClick={onNew} style={iconButtonL(tokens)} title="New Tunnel (⌘N)">
          <IconL name="plus" size={13} color={tokens.text} />
        </button>
      </div>

      {/* List */}
      <div style={{ flex: 1, overflowY: 'auto' }}>
        {sorted.length === 0 ? (
          <div style={{
            padding: '60px 24px', textAlign: 'center', color: tokens.textTertiary, fontSize: 12,
          }}>
            <div style={{ fontSize: 13, color: tokens.textSecondary, marginBottom: 4 }}>
              {searchText ? 'No matches' : 'No tunnels yet'}
            </div>
            <div style={{ fontSize: 11 }}>
              {searchText ? 'Try a different search' : 'Press ⌘N to add one'}
            </div>
          </div>
        ) : sorted.map((t) => {
          const isSel = selectedId === t.id;
          const isRunning = t.state === 'connected' || t.state === 'connecting' || t.state === 'reconnecting';
          return (
            <div
              key={t.id}
              onClick={() => onSelect(t.id)}
              style={{
                padding: `${rowPadY}px 12px ${rowPadY}px 14px`,
                display: 'flex', alignItems: 'flex-start', gap: 10,
                background: isSel ? tokens.selectionBg : 'transparent',
                color: isSel ? '#fff' : tokens.text,
                borderBottom: `0.5px solid ${tokens.hairline}`,
                cursor: 'default', position: 'relative',
                transition: 'background 80ms',
              }}
              onMouseEnter={(e) => { if (!isSel) e.currentTarget.style.background = tokens.surfaceHover; }}
              onMouseLeave={(e) => { if (!isSel) e.currentTarget.style.background = 'transparent'; }}
            >
              <div style={{ paddingTop: 5 }}>
                <StatusDotL state={t.state} tokens={tokens} size={8} />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{
                  display: 'flex', alignItems: 'center', gap: 6, marginBottom: 2,
                }}>
                  <span style={{
                    fontSize: 13, fontWeight: 600, letterSpacing: -0.1,
                    whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  }}>{t.name}</span>
                  <span style={{ marginLeft: 'auto' }} />
                  <TypeChipL type={t.type}
                    tokens={isSel ? { ...tokens, chipBg: 'rgba(255,255,255,0.18)', textSecondary: '#fff' } : tokens} />
                </div>
                <div style={{
                  fontSize: 11, fontFamily: 'ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace',
                  color: isSel ? 'rgba(255,255,255,0.85)' : tokens.textSecondary,
                  whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                  letterSpacing: -0.1,
                }}>{routeDesc(t)}</div>
                {density !== 'compact' && (
                  <div style={{
                    fontSize: 10.5, color: isSel ? 'rgba(255,255,255,0.7)' : tokens.textTertiary,
                    marginTop: 3, display: 'flex', alignItems: 'center', gap: 8,
                  }}>
                    <span>{t.host}</span>
                    {t.state === 'connected' && (
                      <>
                        <span style={{ opacity: 0.5 }}>·</span>
                        <span style={{ fontVariantNumeric: 'tabular-nums' }}>up {fmtUptime(t.uptimeSec)}</span>
                      </>
                    )}
                    {t.state === 'failed' && (
                      <>
                        <span style={{ opacity: 0.5 }}>·</span>
                        <span style={{ color: isSel ? '#FFD2CF' : tokens.danger, fontWeight: 500 }}>
                          Connection failed
                        </span>
                      </>
                    )}
                    {t.state === 'connecting' && (
                      <>
                        <span style={{ opacity: 0.5 }}>·</span>
                        <span style={{ color: isSel ? '#FFE3B8' : tokens.warn }}>Connecting…</span>
                      </>
                    )}
                  </div>
                )}
              </div>
              {/* row hover toggle */}
              <RowToggle
                tunnel={t} isSel={isSel} tokens={tokens}
                onToggle={(e) => { e.stopPropagation(); onToggle(t.id); }}
              />
            </div>
          );
        })}
      </div>

      <div style={{
        padding: '6px 12px', borderTop: `0.5px solid ${tokens.hairline}`,
        fontSize: 10.5, color: tokens.textTertiary,
        display: 'flex', alignItems: 'center', gap: 8,
      }}>
        <span>{sorted.length} {sorted.length === 1 ? 'tunnel' : 'tunnels'}</span>
      </div>
    </section>
  );
}

function RowToggle({ tunnel, isSel, tokens, onToggle }) {
  const isRunning = tunnel.state === 'connected' || tunnel.state === 'connecting' || tunnel.state === 'reconnecting';
  return (
    <button onClick={onToggle} style={{
      alignSelf: 'center', width: 22, height: 22,
      borderRadius: 11, border: 'none', padding: 0, cursor: 'default',
      background: isSel
        ? 'rgba(255,255,255,0.22)'
        : (isRunning ? `${tokens.danger}18` : tokens.surface),
      color: isSel ? '#fff' : (isRunning ? tokens.danger : tokens.accent),
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      transition: 'transform 100ms',
    }}
      onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.08)'}
      onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
      title={isRunning ? 'Stop' : 'Connect'}
    >
      <IconL name={isRunning ? 'stop' : 'play'} size={9}
        color={isSel ? '#fff' : (isRunning ? tokens.danger : tokens.accent)} />
    </button>
  );
}

window.ViaductList = TunnelList;
