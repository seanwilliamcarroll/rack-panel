#!/bin/bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-install.sh"
preflight
install_cadence fast
systemctl list-timers 'panel-fast*' --no-pager
