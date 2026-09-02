#!/usr/bin/env bash
# Remove what install.sh created. Only symlinks that point into this setup are
# touched; your own files, backups, and tmux plugins stay where they are.
set -euo pipefail

INSTALL_ROOT=${CLAUDE_TMUX_HOME:-$HOME/.config/claude-tmux}
BIN_DIR=${CLAUDE_TMUX_BIN:-$HOME/.local/bin}
CLAUDE_SETTINGS=${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}

dry_run=0
remove_plugins=0
reset_settings=0

usage() {
	cat <<'USAGE'
Usage: ./uninstall.sh [options]

Options:
  -n, --dry-run      Print every action, change nothing.
      --plugins      Also delete ~/.tmux/plugins (tpm and the theme plugins).
      --settings     Also remove the agent-team keys from Claude Code settings.
  -h, --help         Show this help and exit.
USAGE
}

while [ $# -gt 0 ]; do
	case "$1" in
	-h | --help)
		usage
		exit 0
		;;
	-n | --dry-run) dry_run=1 ;;
	--plugins) remove_plugins=1 ;;
	--settings) reset_settings=1 ;;
	*)
		echo "uninstall.sh: unknown option '$1' (try --help)" >&2
		exit 2
		;;
	esac
	shift
done

run() {
	if [ "$dry_run" -eq 1 ]; then
		printf '[dry-run] %s\n' "$*"
		return 0
	fi
	"$@"
}

# Only unlink a symlink whose target lives under the install root.
unlink_if_ours() {
	local target=$1
	if [ ! -L "$target" ]; then
		[ -e "$target" ] && echo "skipped $target (not a symlink we created)"
		return 0
	fi
	case "$(readlink "$target")" in
	"$INSTALL_ROOT"/* | "$INSTALL_ROOT")
		run rm "$target"
		echo "removed $target"
		;;
	*) echo "skipped $target (points elsewhere)" ;;
	esac
}

for target in "$HOME/.tmux.conf" "$HOME/.gitmux.conf"; do
	unlink_if_ours "$target"
done

for name in claude-tmux claude-tmux-cleanup claude-tmux-doctor ct ctc; do
	unlink_if_ours "$BIN_DIR/$name"
done

if [ -L "$INSTALL_ROOT" ]; then
	run rm "$INSTALL_ROOT"
	echo "removed $INSTALL_ROOT"
elif [ -d "$INSTALL_ROOT" ]; then
	echo "left $INSTALL_ROOT in place (it is a real directory, not a link)"
fi

if [ "$remove_plugins" -eq 1 ] && [ -d "$HOME/.tmux/plugins" ]; then
	run rm -rf "$HOME/.tmux/plugins"
	echo "removed ~/.tmux/plugins"
fi

if [ "$reset_settings" -eq 1 ]; then
	if ! command -v jq >/dev/null 2>&1; then
		echo "jq not installed; remove the agent-team keys from $CLAUDE_SETTINGS by hand"
	elif [ ! -f "$CLAUDE_SETTINGS" ]; then
		echo "$CLAUDE_SETTINGS does not exist"
	elif [ "$dry_run" -eq 1 ]; then
		echo "[dry-run] would remove agent-team keys from $CLAUDE_SETTINGS"
	else
		cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.backup-$(date +%Y%m%d%H%M%S)"
		jq 'del(.env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS)
        | del(.env.CLAUDE_CODE_SPAWN_BACKEND)
        | del(.teammateMode)' "$CLAUDE_SETTINGS" >"$CLAUDE_SETTINGS.tmp" &&
			mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
		echo "cleaned agent-team keys from $CLAUDE_SETTINGS"
	fi
fi

echo
echo "Backups made by install.sh were left untouched: ls ~/.tmux.conf.backup-* 2>/dev/null"
