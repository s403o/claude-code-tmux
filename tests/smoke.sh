#!/usr/bin/env bash
# Smoke tests: no tmux server is started and nothing on the machine is changed.
# Every script must parse, answer --help, and run its dry-run path cleanly.
set -uo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_DIR" || exit 1

passed=0
failed=0

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
	GREEN=$'\033[32m' RED=$'\033[31m' YELLOW=$'\033[33m' RESET=$'\033[0m'
else
	GREEN="" RED="" YELLOW="" RESET=""
fi

check() {
	local description=$1
	shift
	if output=$("$@" 2>&1); then
		printf '%sok%s   %s\n' "$GREEN" "$RESET" "$description"
		passed=$((passed + 1))
	else
		printf '%sfail%s %s\n' "$RED" "$RESET" "$description"
		printf '%s\n' "$output" | sed 's/^/       /'
		failed=$((failed + 1))
	fi
}

for script in install.sh uninstall.sh bin/* scripts/*.sh tests/smoke.sh; do
	check "parses: $script" bash -n "$script"
	check "executable: $script" test -x "$script"
done

for script in install.sh uninstall.sh bin/claude-tmux bin/claude-tmux-cleanup; do
	check "--help works: $script" "./$script" --help
done

check "install.sh --dry-run" ./install.sh --dry-run --no-brew --yes
check "uninstall.sh --dry-run" ./uninstall.sh --dry-run

# The status scripts must print something the tmux status bar can render.
# shellcheck disable=SC2016 # the subshell must run inside the checked shell
check "ram.sh prints a value" bash -c '[ -n "$(./scripts/ram.sh)" ]'
# shellcheck disable=SC2016
check "load.sh prints a value" bash -c '[ -n "$(./scripts/load.sh)" ]'

# Cleanup refuses to run inside tmux, and does nothing on a dry run outside it.
check "cleanup refuses to run inside tmux" \
	bash -c 'TMUX=fake ./bin/claude-tmux-cleanup --all --force 2>/dev/null; [ $? -eq 1 ]'
check "cleanup dry-run outside tmux" \
	bash -c 'env -u TMUX ./bin/claude-tmux-cleanup --all --dry-run </dev/null'

# tmux must accept the config. Skipped where the plugins are not installed,
# because the run-shell lines would fail for a reason the config cannot control.
if command -v tmux >/dev/null 2>&1 && [ -d "$HOME/.tmux/plugins/tpm" ]; then
	check "tmux loads config/tmux.conf" bash -c '
		tmux -f config/tmux.conf -L claude-tmux-smoke start-server \; kill-server'
else
	printf '%sskip%s %s\n' "$YELLOW" "$RESET" "tmux config load (tmux or plugins missing)"
fi

if command -v jq >/dev/null 2>&1; then
	check "claude-settings.json is valid JSON" jq empty config/claude-settings.json
fi

printf '\n%d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
