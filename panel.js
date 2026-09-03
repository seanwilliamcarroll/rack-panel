const LAT = CONFIG.lat, LON = CONFIG.lon;

async function weather() {
  const url = `https://api.open-meteo.com/v1/forecast`
    + `?latitude=${LAT}&longitude=${LON}`
    + `&current=temperature_2m,weather_code,wind_speed_10m`
    + `&temperature_unit=fahrenheit&wind_speed_unit=mph`
    + `&timezone=America/New_York`;
  try {
    const r = await fetch(url);
    const d = await r.json();
    document.getElementById('wx-temp').textContent =
      Math.round(d.current.temperature_2m) + '\u00B0';
    document.getElementById('wx-desc').textContent =
      wmo(d.current.weather_code) + ' \u00B7 '
      + Math.round(d.current.wind_speed_10m) + ' mph';
    mark('weather', false);
  } catch (e) {
    mark('weather', true);
  }
}

function wmo(c) {
  if (c === 0) return 'Clear';
  if (c <= 3) return 'Cloudy';
  if (c <= 48) return 'Fog';
  if (c <= 67) return 'Rain';
  if (c <= 77) return 'Snow';
  if (c <= 82) return 'Showers';
  return 'Storm';
}

function mark(id, stale) {
  document.getElementById(id).classList.toggle('stale', stale);
}

weather();
setInterval(weather, 10 * 60 * 1000);

async function vitals() {
  try {
    const r = await fetch('/data/vitals.json');
    const d = await r.json();

    document.getElementById('pi-temp').textContent =
      Math.round(d.temp_c) + '\u00B0C';
    document.getElementById('pi-sub').textContent =
      'load ' + d.load1
      + ' \u00B7 mem ' + d.mem_used_pct + '%'
      + ' \u00B7 disk ' + d.disk_used_pct + '%';

    const ageSec = Math.round(Date.now() / 1000 - d.ts);
    document.getElementById('pi-age').textContent = ageSec + 's ago';
    mark('vitals', ageSec > 90);
  } catch (e) {
    mark('vitals', true);
  }
}

vitals();
setInterval(vitals, 30 * 1000);


async function hosts() {
  try {
    const r = await fetch('/data/hosts.json');
    const d = await r.json();

    const ul = document.getElementById('host-list');
    ul.innerHTML = '';

    for (const h of d.hosts) {
      const li = document.createElement('li');
      li.className = 's' + h.status;
      li.textContent = h.name;

      if (h.ms != null) {
        const ms = document.createElement('span');
        ms.className = 'ms';
        ms.textContent = h.ms + 'ms';
        li.appendChild(ms);
      }

      // Only show uptime when it is not perfect — a column of 100% is noise.
      if (h.up24 != null && h.up24 < 0.9999) {
        const u = document.createElement('span');
        u.className = 'u24';
        u.textContent = (h.up24 * 100).toFixed(1) + '%';
        li.appendChild(u);
      }

      ul.appendChild(li);
    }

    const ageSec = Math.round(Date.now() / 1000 - d.ts);
    document.getElementById('host-age').textContent = ageSec + 's ago';
    mark('hosts', ageSec > 90);
  } catch (e) {
    console.error('hosts:', e);
    mark('hosts', true);
  }
}

hosts();
setInterval(hosts, 30 * 1000);

function bps(n) {
  if (n >= 1e9) return (n / 1e9).toFixed(1) + ' Gb/s';
  if (n >= 1e6) return (n / 1e6).toFixed(1) + ' Mb/s';
  if (n >= 1e3) return Math.round(n / 1e3) + ' kb/s';
  return n + ' b/s';
}

/**
 * Draw a sparkline into an existing <polyline>.
 *   id       — element id
 *   values   — array of numbers, oldest first
 *   max      — optional shared vertical scale; defaults to the series peak
 *   capacity — optional horizontal capacity. When the buffer is not yet full,
 *              the line right-aligns into this window instead of stretching
 *              a few points across the whole tile.
 */
function spark(id, values, max, capacity) {
  const el = document.getElementById(id);
  if (!values || values.length < 2) { el.setAttribute('points', ''); return; }

  const m = max || Math.max(...values, 1);
  const n = Math.max(capacity || values.length, 2);
  const offset = n - values.length;

  const pts = values.map((v, i) =>
    ((i + offset) / (n - 1) * 100) + ',' + (30 - v / m * 28)
  ).join(' ');

  el.setAttribute('points', pts);
}

async function wan() {
  try {
    const r = await fetch('/data/wan.json');
    const d = await r.json();

    document.getElementById('wan-rx').textContent = bps(d.rx_bps);
    document.getElementById('wan-tx').textContent = bps(d.tx_bps);

    // One shared scale, or up and down each normalise to their own peak and
    // comparing them becomes meaningless. The floor stops an idle network's
    // background chatter being magnified into a mountain range.
    const scale = Math.max(...d.rx_hist, ...d.tx_hist, CONFIG.wanSparkFloor);
    spark('wan-rx-line', d.rx_hist, scale, CONFIG.wanHistoryPoints);
    spark('wan-tx-line', d.tx_hist, scale, CONFIG.wanHistoryPoints);

    const ageSec = Math.round(Date.now() / 1000 - d.ts);
    document.getElementById('wan-age').textContent = ageSec + 's ago';
    mark('wan', ageSec > 90);
  } catch (e) {
    console.error('wan:', e);
    mark('wan', true);
  }
}

wan();
setInterval(wan, 30 * 1000);

function bytes(n) {
  if (n >= 1e9) return (n / 1e9).toFixed(1) + ' GB';
  if (n >= 1e6) return (n / 1e6).toFixed(1) + ' MB';
  if (n >= 1e3) return Math.round(n / 1e3) + ' kB';
  return n + ' B';
}

async function flows() {
  try {
    const r = await fetch('/data/flows.json');
    const d = await r.json();

    const ul = document.getElementById('flow-list');
    ul.innerHTML = '';

    const max = Math.max(...d.hosts.map(h => h.total), 1);

    for (const h of d.hosts) {
      const li = document.createElement('li');

      const bar = document.createElement('div');
      bar.className = 'bar';
      bar.style.width = (h.total / max * 100) + '%';
      li.appendChild(bar);

      const name = document.createElement('span');
      name.className = 'fname';
      name.textContent = h.name;
      name.title = h.addr;
      li.appendChild(name);

      const io = document.createElement('span');
      io.className = 'fio';
      io.textContent = '\u2191 ' + bytes(h.tx) + '  \u2193 ' + bytes(h.rx);
      li.appendChild(io);

      ul.appendChild(li);
    }

    const ageSec = Math.round(Date.now() / 1000 - d.ts);
    document.getElementById('flow-age').textContent = ageSec + 's ago';
    mark('flows', ageSec > 900);
  } catch (e) {
    console.error('flows:', e);
    mark('flows', true);
  }
}

flows();
setInterval(flows, 5 * 60 * 1000);
