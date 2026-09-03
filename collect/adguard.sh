#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/config.env"

curl -sf -u "$ADGUARD_USER:$ADGUARD_PASS" "$ADGUARD_URL/control/stats" \
  | jq -c '{
      ts: (now | floor),
      queries: .num_dns_queries,
      blocked: .num_blocked_filtering,
      avg_ms: .avg_processing_time,
      units: .time_units,
      series: .dns_queries,
      blocked_series: .blocked_filtering
    }' > "$DATA_DIR/adguard.json.tmp"

mv "$DATA_DIR/adguard.json.tmp" "$DATA_DIR/adguard.json"
