#!/usr/bin/env bash
# Install the Claude Code + tmux agent-team setup.
#
# Everything here is idempotent: re-running it repairs whatever is missing and
# leaves the rest alone. Existing files are backed up before being replaced.
set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
INSTALL_ROOT=${CLAUDE_TMUX_HOME:-$HOME/.config/claude-tmux}
BIN_DIR=${CLAUDE_TMUX_BIN:-$HOME/.local/bin}
CLAUDE_SETTINGS=${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}
BACKUP_SUFFIX=$(date +%Y%m%d%H%M%S)

# name -> "repo#ref"; TPM last so it can see the others already on disk
PLUGINS=(
	"tmux|https://github.com/catppuccin/tmux|v2.1.3"
	"tmux-cpu|https://github.com/tmux-plugins/tmux-cpu|master"
	"tmux-battery|https://github.com/tmux-plugins/tmux-battery|master"
	"tpm|https://github.com/tmux-plugins/tpm|master"
)

dry_run=0
use_brew=1
assume_yes=0
short_names=1

usage() {
	cat <<'USAGE'
Usage: ./install.sh [options]

Options:
  -n, --dry-run      Print every action, change nothing.
  -y, --yes          Do not ask before replacing existing files.
      --no-brew      Never call Homebrew, only report missing dependencies.
      --no-short     Skip the ct / ctc shortcut symlinks.
      --bin DIR      Where to link the commands. Default: ~/.local/bin
  -h, --help         Show this help and exit.

Environment:
  CLAUDE_TMUX_HOME   Install root. Default: ~/.config/claude-tmux
  CLAUDE_SETTINGS    Claude Code settings file. Default: ~/.claude/settings.json
USAGE
}

while [ $# -gt 0 ]; do
	case "$1" in
	-h | --help)
		usage
		exit 0
		;;
	-n | --dry-run) dry_run=1 ;;
	-y | --yes) assume_yes=1 ;;
	--no-brew) use_brew=0 ;;
	--no-short) short_names=0 ;;
	--bin)
		[ $# -ge 2 ] || {
			echo "--bin needs a value" >&2
			exit 2
		}
		BIN_DIR=$2
		shift
		;;
	*)
		echo "install.sh: unknown option '$1' (try --help)" >&2
		exit 2
		;;
	esac
	shift
done

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
info() { printf '    %s\n' "$1"; }
run() {
	if [ "$dry_run" -eq 1 ]; then
		printf '    [dry-run] %s\n' "$*"
		return 0
	fi
	"$@"
}

confirm() {
	[ "$assume_yes" -eq 1 ] && return 0
	[ "$dry_run" -eq 1 ] && return 0
	local answer
	read -r -p "    $1 [y/N] " answer
	case "$answer" in [yY] | [yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}

# Replace target with a symlink to source, backing up anything already there.
link() {
	local source=$1 target=$2
	if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
		info "$target already links to $source"
		return 0
	fi
	if [ -e "$target" ] || [ -L "$target" ]; then
		if ! confirm "Replace $target? (a backup will be kept)"; then
			info "left $target alone"
			return 0
		fi
		run mv "$target" "$target.backup-$BACKUP_SUFFIX"
		info "backed up to $target.backup-$BACKUP_SUFFIX"
	fi
	run mkdir -p "$(dirname "$target")"
	run ln -s "$source" "$target"
	info "linked $target -> $source"
}

# --- Dependencies ------------------------------------------------------------

step "Checking dependencies"
missing=()
for command_name in tmux git; do
	command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
done
# Optional but recommended: gitmux draws the branch, jq patches settings.json
for command_name in gitmux jq; do
	command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
done

if [ ${#missing[@]} -eq 0 ]; then
	info "all dependencies present"
elif [ "$use_brew" -eq 1 ] && command -v brew >/dev/null 2>&1; then
	info "installing with Homebrew: ${missing[*]}"
	run brew install "${missing[@]}"
else
	info "missing: ${missing[*]}"
	info "install them first (macOS: brew install ${missing[*]})"
	case " ${missing[*]} " in
	*" tmux "* | *" git "*)
		echo "tmux and git are required, stopping." >&2
		exit 1
		;;
	esac
fi

# --- Repository files --------------------------------------------------------

step "Linking the repository into $INSTALL_ROOT"
if [ "$REPO_DIR" = "$INSTALL_ROOT" ]; then
	info "repository is already checked out at $INSTALL_ROOT"
else
	run mkdir -p "$(dirname "$INSTALL_ROOT")"
	link "$REPO_DIR" "$INSTALL_ROOT"
fi

step "Linking configuration"
link "$INSTALL_ROOT/config/tmux.conf" "$HOME/.tmux.conf"
link "$INSTALL_ROOT/config/gitmux.conf" "$HOME/.gitmux.conf"

step "Linking commands into $BIN_DIR"
run mkdir -p "$BIN_DIR"
for command_path in "$REPO_DIR"/bin/*; do
	link "$INSTALL_ROOT/bin/$(basename "$command_path")" "$BIN_DIR/$(basename "$command_path")"
done
if [ "$short_names" -eq 1 ]; then
	link "$INSTALL_ROOT/bin/claude-tmux" "$BIN_DIR/ct"
	link "$INSTALL_ROOT/bin/claude-tmux-cleanup" "$BIN_DIR/ctc"
fi

case ":$PATH:" in
*":$BIN_DIR:"*) : ;;
*) info "note: $BIN_DIR is not on PATH — add 'export PATH=\"$BIN_DIR:\$PATH\"' to your shell rc" ;;
esac

# --- tmux plugins ------------------------------------------------------------

step "Installing tmux plugins"
for entry in "${PLUGINS[@]}"; do
	IFS='|' read -r name url ref <<<"$entry"
	destination="$HOME/.tmux/plugins/$name"
	if [ -d "$destination/.git" ]; then
		info "$name already cloned"
		continue
	fi
	# advice.detachedHead off: cloning a tag is intentional here, not a mistake
	run git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$ref" "$url" "$destination"
	info "cloned $name at $ref"
done

# --- Claude Code settings ----------------------------------------------------

step "Enabling agent teams in Claude Code"
if ! command -v jq >/dev/null 2>&1; then
	info "jq is not installed; merge config/claude-settings.json into $CLAUDE_SETTINGS by hand"
elif [ "$dry_run" -eq 1 ]; then
	info "[dry-run] would merge config/claude-settings.json into $CLAUDE_SETTINGS"
else
	mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
	[ -f "$CLAUDE_SETTINGS" ] || echo '{}' >"$CLAUDE_SETTINGS"
	if ! jq empty "$CLAUDE_SETTINGS" 2>/dev/null; then
		echo "    $CLAUDE_SETTINGS is not valid JSON, refusing to touch it." >&2
		exit 1
	fi
	cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.backup-$BACKUP_SUFFIX"
	# Deep merge so existing keys (hooks, permissions, model) survive untouched.
	jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" "$REPO_DIR/config/claude-settings.json" \
		>"$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
	info "merged agent-team settings (backup: $CLAUDE_SETTINGS.backup-$BACKUP_SUFFIX)"
fi

# --- Reload ------------------------------------------------------------------

step "Reloading tmux"
if [ "$dry_run" -eq 0 ] && tmux list-sessions >/dev/null 2>&1; then
	if tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1; then
		info "running tmux server reloaded"
	else
		info "reload failed; press prefix + r inside tmux"
	fi
else
	info "no tmux server running, nothing to reload"
fi

step "Done"
info "Start a session with:  claude-tmux"
info "Check the install with: claude-tmux-doctor"
