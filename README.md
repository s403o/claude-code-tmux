# claude-code-tmux

Watch Claude Code agent teams work side by side, each teammate in its own tmux pane — installed, themed and cleaned up by scripts instead of by hand.

Claude Code can run a team of agents in parallel. When it is started from inside tmux it spawns every teammate into a real pane, so you see all of them at once instead of a single scrolling log. This repository is the whole setup around that: the tmux config, the status bar, the launcher, a cleanup command for the sessions and processes long runs leave behind, and a doctor command that tells you which piece is missing.

---

## What you get

| Piece | What it does |
| --- | --- |
| `claude-tmux` (`ct`) | Starts or re-attaches a tmux session and runs Claude Code inside it. One session per project by default. |
| `claude-tmux-cleanup` (`ctc`) | Lists sessions and stray Claude processes, then kills what you pick. Supports `--all`, `--force`, `--dry-run`, `--prune`. |
| `claude-tmux-doctor` | Checks dependencies, symlinks, plugins, PATH and the Claude Code settings keys. Exits non-zero on failures. |
| `config/tmux.conf` | Ctrl+a prefix, mouse on, 50k scrollback, pane labels, agent-team layouts, Catppuccin Mocha status bar. |
| `scripts/ram.sh`, `scripts/load.sh` | Status bar readings that macOS's built-in tmux plugins do not provide. |
| `install.sh` / `uninstall.sh` | Idempotent, backs up whatever it replaces, `--dry-run` on both. |

## Requirements

- macOS or Linux with **tmux 3.0+** and git
- [Claude Code](https://claude.com/claude-code) on your PATH
- A terminal with true colour and a Nerd Font (iTerm2, Kitty, WezTerm, Ghostty, Warp). Apple Terminal will not render the theme correctly.
- Optional: `gitmux` for the branch in the status bar, `jq` so the installer can patch `settings.json`

## Install

```bash
git clone https://github.com/s403o/claude-code-tmux.git
cd claude-code-tmux
./install.sh            # add --dry-run first if you want to see every action
```

The installer:

1. Installs missing dependencies with Homebrew (skip with `--no-brew`)
2. Links the checkout to `~/.config/claude-tmux`
3. Links `~/.tmux.conf` and `~/.gitmux.conf`, backing up existing files as `*.backup-<timestamp>`
4. Links the commands into `~/.local/bin`, plus `ct` and `ctc` shortcuts
5. Clones tpm, catppuccin, tmux-cpu and tmux-battery at pinned versions
6. Deep-merges the agent-team keys into `~/.claude/settings.json`, keeping your existing hooks, permissions and model
7. Reloads a running tmux server

Then check it:

```bash
claude-tmux-doctor
```

## Use it

```bash
ct                        # session named after the current directory
ct api ~/code/api         # explicit session name and directory
ct --list                 # what is running
ct -- --model sonnet      # pass flags through to claude
```

Ask Claude Code for a team ("split this across three agents") and each teammate appears in its own pane.

When you are done:

```bash
ctc                       # walk through the sessions, kill what you choose
ctc --all --force         # kill every Claude session, no questions
ctc --prune --dry-run     # list Claude processes with no pane, kill nothing
```

`claude-tmux-cleanup` refuses to run inside tmux, never kills the Claude session that launched it, and ignores editor-hosted Claude processes (VS Code, JetBrains) because those have no controlling terminal.

## Keys

Prefix is **Ctrl+a**.

| Keys | Action |
| --- | --- |
| `prefix` + `\|` / `-` | Split right / down, in the current pane's directory |
| `Alt` + arrows | Move between panes, no prefix needed |
| `Ctrl` + `Alt` + arrows | Resize the current pane |
| `prefix` + `t` / `v` / `h` | Tiled / main-vertical / main-horizontal layout |
| `prefix` + `z` | Zoom one agent to full screen, again to restore |
| `prefix` + `S` | Toggle synchronize-panes (type into every pane at once) |
| `prefix` + `x` | Kill the current pane |
| `prefix` + `d` | Detach; agents keep running |
| `prefix` + `r` | Reload the config |
| `prefix` + `I` | Update the tmux plugins |
| Drag with the mouse | Select text, copied straight to the clipboard |

More detail in [docs/CHEATSHEET.md](docs/CHEATSHEET.md).

## How the agent-team part works

Three settings in `~/.claude/settings.json` do the actual work:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "CLAUDE_CODE_SPAWN_BACKEND": "tmux"
  },
  "teammateMode": "tmux"
}
```

`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` turns on teams, and the other two tell Claude Code to spawn each teammate into a tmux pane rather than running it hidden. Agent teams are an experimental feature, so expect the flag names to move; `claude-tmux-doctor` reports what the file currently says.

Everything else is ergonomics: `remain-on-exit off` so finished agents' panes disappear, pane labels so you can tell the agents apart, and layouts bound to single keys because a five-agent tiled view needs rearranging often.

## Uninstall

```bash
./uninstall.sh                        # remove the symlinks
./uninstall.sh --plugins --settings   # also drop tmux plugins and the settings keys
```

Only symlinks pointing into the install root are removed, and backups are left alone.

## Development

```bash
make check    # shellcheck + shfmt + smoke tests
make test     # smoke tests only, nothing on the machine is changed
```

CI runs the same checks on macOS and Linux.

## Troubleshooting

**Teammates run but no panes appear.** Claude Code was not started from inside tmux, or the settings keys are missing. Run `claude-tmux-doctor`.

**Status bar shows boxes or question marks.** The font is not a Nerd Font. Install one (`brew install --cask font-jetbrains-mono-nerd-font`) and select it in your terminal.

**No git branch in the status bar.** `gitmux` is not installed: `brew install gitmux`.

**Colours look flat.** The terminal does not support true colour. Apple Terminal is the usual cause.

**Config edits do nothing.** tmux caches until reloaded: `prefix` + `r`, or `tmux kill-server` for a clean start.

**`ct: command not found`.** `~/.local/bin` is not on your PATH: `export PATH="$HOME/.local/bin:$PATH"`.

## Licence

MIT. See [LICENSE](LICENSE).
