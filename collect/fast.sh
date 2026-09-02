#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/config.env"
OUT="$DATA_DIR"

temp=$(awk '{printf "%.1f", $1/1000}' /sys/class/thermal/thermal_zone0/temp)
load=$(awk '{print $1}' /proc/loadavg)
uptime_s=$(awk '{print int($1)}' /proc/uptime)
mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
mem_avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
disk_pct=$(df --output=pcent / | tail -1 | tr -dc '0-9')

cat > "$OUT/vitals.json.tmp" <<EOF
{
  "ts": $(date +%s),
  "temp_c": $temp,
  "load1": $load,
  "uptime_s": $uptime_s,
  "mem_used_pct": $(( (mem_total - mem_avail) * 100 / mem_total )),
  "disk_used_pct": $disk_pct
}
EOF
mv "$OUT/vitals.json.tmp" "$OUT/vitals.json"
