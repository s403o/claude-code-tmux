#!/usr/bin/env bash
# Physical memory in use, formatted for the tmux status bar: "19.8G/24G 82%".
# "In use" mirrors Activity Monitor's Memory Used: active + wired + compressed.
# Inactive and speculative pages are reclaimable, so they are not counted.
set -euo pipefail

total_bytes=$(sysctl -n hw.memsize)

vm_stat | awk -v total="$total_bytes" '
  /page size of/                 { page = $8 }
  /Pages active/                 { gsub(/\./, "", $3); active = $3 }
  /Pages wired down/             { gsub(/\./, "", $4); wired = $4 }
  /Pages occupied by compressor/ { gsub(/\./, "", $5); compressed = $5 }
  END {
    if (page == 0) page = 4096
    used = (active + wired + compressed) * page
    printf "%.1fG/%.0fG %.0f%%", used / 1073741824, total / 1073741824, used / total * 100
  }
'
