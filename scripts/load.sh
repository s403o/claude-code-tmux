#!/usr/bin/env bash
# Load averages as a percentage of available cores: "23% 18% 15%".
# Percent instead of raw numbers so the reading is comparable across machines:
# 100% means the run queue exactly matches the core count.
set -euo pipefail

if [ -r /proc/loadavg ]; then
	cores=$(nproc)
	read -r one five fifteen _ </proc/loadavg
else
	cores=$(sysctl -n hw.ncpu)
	read -r one five fifteen < <(sysctl -n vm.loadavg | tr -d '{}')
fi

awk -v c="$cores" -v a="$one" -v b="$five" -v d="$fifteen" \
	'BEGIN { printf "%.0f%% %.0f%% %.0f%%", a / c * 100, b / c * 100, d / c * 100 }'
