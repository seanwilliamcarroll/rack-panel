#!/bin/bash
# Sourced by install-fast.sh / install-slow.sh. Not executable on its own.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

preflight() {
  if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user; it will sudo where needed." >&2
    exit 1
  fi
  [ -f "$REPO/config.js" ] \
    || echo "WARNING: config.js missing (cp config.example.js config.js)" >&2
  [ -f "$REPO/collect/config.env" ] \
    || echo "WARNING: collect/config.env missing" >&2

  chmod +x "$REPO"/collect/*.sh
  sudo install -d -o "$USER" -g "$USER" /var/lib/panel-data
}

# install_cadence <fast|slow>
install_cadence() {
  local c="$1"
  local svc="panel-$c.service" tmr="panel-$c.timer"

  for f in "$svc" "$tmr"; do
    [ -f "$REPO/systemd/$f" ] || { echo "missing: systemd/$f" >&2; exit 1; }
  done

  sudo install -m 644 "$REPO/systemd/$svc" "/etc/systemd/system/$svc"
  sudo install -m 644 "$REPO/systemd/$tmr" "/etc/systemd/system/$tmr"

  sudo systemctl daemon-reload
  sudo systemctl enable --now "$tmr"
  sudo systemctl restart "$tmr"
  sudo systemctl start "$svc"          # run once now, don't wait for the tick

  echo "installed: $c"
}
