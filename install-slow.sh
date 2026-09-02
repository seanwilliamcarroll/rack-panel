#!/bin/bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib-install.sh"
preflight
install_cadence slow
systemctl list-timers 'panel-slow*' --no-pager
