#!/usr/bin/env bash
# Physical memory in use, formatted for the tmux status bar: "19.8G/24G 82%".
# macOS counts what Activity Monitor calls Memory Used (active + wired +
# compressed); Linux uses MemAvailable, which is the same idea: pages that
# would have to be reclaimed before a new allocation can be served.
set -euo pipefail

case "$(uname -s)" in
Darwin)
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
	;;
*)
	awk '
    /^MemTotal:/     { total = $2 }
    /^MemAvailable:/ { available = $2 }
    END {
      if (total == 0) exit 1
      used = total - available
      printf "%.1fG/%.0fG %.0f%%", used / 1048576, total / 1048576, used / total * 100
    }
  ' /proc/meminfo
	;;
esac
