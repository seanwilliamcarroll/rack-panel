#!/bin/bash
# Deliberately no `set -e`: one failing collector must not stop the others.
d="$(dirname "$0")"
for s in vitals.sh hosts.sh wan.sh; do
  [ -x "$d/$s" ] && "$d/$s" || echo "collector failed: $s" >&2
done
