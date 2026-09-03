#!/bin/bash
d="$(dirname "$0")"
for s in flows.sh; do
  [ -x "$d/$s" ] && "$d/$s" || echo "collector failed: $s" >&2
done
