# Troubleshooting

**Teammates run but no panes appear.** Claude Code was not started from inside tmux, or the settings keys are missing. Run `claude-tmux-doctor`.

**Status bar shows boxes or question marks.** The font is not a Nerd Font. Install one (`brew install --cask font-jetbrains-mono-nerd-font`) and select it in your terminal.

**No git branch in the status bar.** `gitmux` is not installed: `brew install gitmux`.

**Colours look flat.** The terminal does not support true colour. Apple Terminal is the usual cause; iTerm2, Kitty, WezTerm, Ghostty and Warp all work.

**Config edits do nothing.** tmux caches until reloaded: `prefix` + `r`, or `tmux kill-server` for a clean start.

**`ct: command not found`.** `~/.local/bin` is not on your PATH: `export PATH="$HOME/.local/bin:$PATH"`.

**A pane is stuck after an agent died.** `prefix` + `x` kills the pane; `ctc --prune --dry-run` lists Claude processes with no pane at all.

**Reverting the install.** `./uninstall.sh` removes only symlinks pointing into the install root. Your originals are next to them as `*.backup-<timestamp>`.

## Reporting a problem

Include the output of `claude-tmux-doctor`, your `tmux -V`, and the terminal you use.
