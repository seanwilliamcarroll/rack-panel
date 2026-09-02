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
