#!/bin/bash
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$REPO/install-fast.sh"
"$REPO/install-slow.sh"

echo
systemctl list-timers 'panel-*' --no-pager
echo
ls -la /var/lib/panel-data/
