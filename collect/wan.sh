#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/config.env"

STATE=$DATA_DIR/.wan.state
HIST=$DATA_DIR/.wan.hist
POINTS=${WAN_HISTORY_POINTS:-120}

IN_OID=.1.3.6.1.2.1.31.1.1.1.6.$WAN_IFINDEX
OUT_OID=.1.3.6.1.2.1.31.1.1.1.10.$WAN_IFINDEX

rx_c=$(snmpget -v2c -c "$SNMP_COMMUNITY" -Oqv "$ROUTER_IP" "$IN_OID")
tx_c=$(snmpget -v2c -c "$SNMP_COMMUNITY" -Oqv "$ROUTER_IP" "$OUT_OID")
now=$(date +%s)

if [ -f "$STATE" ]; then
  read -r p_rx p_tx p_ts < "$STATE"
  dt=$(( now - p_ts ))
  if [ "$dt" -gt 0 ] && [ "$rx_c" -ge "$p_rx" ] && [ "$tx_c" -ge "$p_tx" ]; then
    rx=$(( (rx_c - p_rx) * 8 / dt ))
    tx=$(( (tx_c - p_tx) * 8 / dt ))

    echo "$rx $tx" >> "$HIST"
    tail -n "$POINTS" "$HIST" > "$HIST.tmp" && mv "$HIST.tmp" "$HIST"

    jq -n --argjson ts "$now" --argjson rx "$rx" --argjson tx "$tx" \
          --rawfile h "$HIST" '{
      ts: $ts, rx_bps: $rx, tx_bps: $tx,
      rx_hist: [$h | split("\n")[] | select(length>0) | split(" ")[0] | tonumber],
      tx_hist: [$h | split("\n")[] | select(length>0) | split(" ")[1] | tonumber]
    }' > "$DATA_DIR/wan.json.tmp"

    mv "$DATA_DIR/wan.json.tmp" "$DATA_DIR/wan.json"
  fi
fi

echo "$rx_c $tx_c $now" > "$STATE"
