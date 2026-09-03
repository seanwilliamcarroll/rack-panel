#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/config.env"

FROM=$(date -d "$FLOWS_MINUTES minutes ago" +%Y/%m/%d.%H:%M:%S)
TO=$(date +%Y/%m/%d.%H:%M:%S)
W="$FROM-$TO"

# Build "src net A or src net B" from the configured list.
src_f=""; dst_f=""
for n in $INTERNAL_NETS; do
  src_f="${src_f:+$src_f or }src net $n"
  dst_f="${dst_f:+$dst_f or }dst net $n"
done

tx_raw=$(nfdump -R "$NFDUMP_DIR" -t "$W" "$src_f" -s srcip/bytes -n 50 -o json -q 2>/dev/null || true)
rx_raw=$(nfdump -R "$NFDUMP_DIR" -t "$W" "$dst_f" -s dstip/bytes -n 50 -o json -q 2>/dev/null || true)

tx=$(printf '%s\n' "$tx_raw" | jq -s '[.[] | {key: .srcip, value: .bytes}] | from_entries')
rx=$(printf '%s\n' "$rx_raw" | jq -s '[.[] | {key: .dstip, value: .bytes}] | from_entries')

names=$(for kv in $HOST_NAMES; do
          printf '{"%s":"%s"}\n' "${kv%%=*}" "${kv#*=}"
        done | jq -s 'add // {}')

jq -n --argjson tx "$tx" --argjson rx "$rx" --argjson names "$names" \
      --argjson ts "$(date +%s)" --argjson n "$FLOWS_COUNT" '
  { ts: $ts,
    hosts: ( ($tx + $rx | keys)
      | map({ addr: .,
              name: ($names[.] // .),
              tx:   ($tx[.] // 0),
              rx:   ($rx[.] // 0) })
      | map(. + {total: (.tx + .rx)})
      | sort_by(-.total)
      | .[0:$n] )
  }' > "$DATA_DIR/flows.json.tmp"

mv "$DATA_DIR/flows.json.tmp" "$DATA_DIR/flows.json"
