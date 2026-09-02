#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/config.env"

meta=$(curl -sf "$KUMA_URL/api/status-page/$KUMA_SLUG")
beats=$(curl -sf "$KUMA_URL/api/status-page/heartbeat/$KUMA_SLUG")

jq -n --argjson m "$meta" --argjson b "$beats" '{
  ts: (now | floor),
  hosts: [
    $m.publicGroupList[].monitorList[]
    | . as $mon
    | ($b.heartbeatList[($mon.id | tostring)] // [] | last) as $hb
    | {
        name:   $mon.name,
        status: ($hb.status // -1),
        ms:     ($hb.ping // null),
        up24:   ($b.uptimeList[($mon.id | tostring) + "_24"] // null)
      }
  ]
}' > "$DATA_DIR/hosts.json.tmp"

mv "$DATA_DIR/hosts.json.tmp" "$DATA_DIR/hosts.json"
