# Cheat sheet

Prefix is **Ctrl+a** (`prefix` below). Press the prefix, release, then the key.

## Starting a team

Type the prompt inside a session started with `ct`. Name the agent count and
give each agent a job it can finish on its own:

```
Create a team of 3: one agent to map every service in the compose files and
its env vars, one to check the k3d cluster config, one to list mismatches
between them.
```

One pane per teammate, plus your lead pane. `prefix` + `t` to tile them,
`prefix` + `z` to zoom one, `prefix` + `d` to detach and leave them running.

### A demo team, no real work

The prompt behind the screenshot in the README — the agents only introduce
themselves, so the panes appear instantly:

```
Create a team of 3, and have each agent print one line saying hi and what its
role is: agent 1 maps the compose services and env vars, agent 2 checks the k3d
cluster config, agent 3 lists mismatches between them. No tools, no file reads.
```

### More prompts in the same shape

```
Create a team of 3: one to audit the Terraform modules for hardcoded secrets,
one to diff the staging and prod variable files, one to write up what has
drifted.

Create a team of 4, one per service (api, worker, scheduler, web): each one
upgrades its own Dockerfile to the new base image and runs its test suite.

Create a team of 2: one to reproduce the failing integration test, one to
bisect the last 20 commits for where it broke. Report to me before changing
anything.
```

### What makes a team prompt work

- **Name the count.** "A team of 3" is unambiguous; "some agents" is not.
- **Give each agent a job it can finish alone.** Agents that need each other's
  output serialise, and you lose the point of watching them in parallel.
- **Split by file, service or directory** so two agents never edit one file.
- **Say what to do at the end** ("list mismatches", "report to me before
  changing anything") so the run has a clear finish line.

## Sessions

| Command | Action |
| --- | --- |
| `ct` | Start or attach a session named after the current directory |
| `ct name dir` | Start or attach a named session in a directory |
| `ct --list` | List running sessions |
| `ctc` | Interactive cleanup |
| `prefix` + `d` | Detach; everything keeps running |
| `prefix` + `s` | Session picker |
| `prefix` + `$` | Rename the session |
| `tmux attach -t name` | Re-attach from anywhere |

## Panes

| Keys | Action |
| --- | --- |
| `prefix` + `\|` | Split right |
| `prefix` + `-` | Split down |
| `Alt` + arrows | Move focus |
| `Ctrl` + `Alt` + arrows | Resize |
| `prefix` + `z` | Zoom / unzoom the focused pane |
| `prefix` + `x` | Kill the pane |
| `prefix` + `q` | Show pane numbers (press one to jump) |
| `prefix` + `{` / `}` | Swap the pane with the previous / next one |
| `prefix` + `!` | Break the pane out into its own window |

## Layouts for a team

| Keys | Layout | Good for |
| --- | --- | --- |
| `prefix` + `t` | Tiled | Three or more agents, equal attention |
| `prefix` + `v` | Main vertical | You drive on the left, agents report on the right |
| `prefix` + `h` | Main horizontal | Wide monitor, agents in a row underneath |
| `prefix` + `space` | Cycle the built-in layouts | Quick reshuffle |

## Copy mode

| Keys | Action |
| --- | --- |
| Mouse drag | Select and copy to the system clipboard |
| `prefix` + `[` | Enter copy mode (scroll back through an agent's output) |
| `q` | Leave copy mode |
| `prefix` + `]` | Paste the tmux buffer |
| `prefix` + `S` | Toggle synchronize-panes: type once, every pane receives it |

## Maintenance

| Command | Action |
| --- | --- |
| `prefix` + `r` | Reload the config |
| `prefix` + `I` | Install or update plugins via tpm |
| `claude-tmux-doctor` | Check the whole setup |
| `ctc --all --force` | Kill every Claude session |
| `ctc --prune --dry-run` | List Claude processes with no pane |
| `tmux kill-server` | Nuclear option: end every session |

## Reading the status bar

```
 session   branch   directory                    CPU 12%   RAM 18.6G/24G 78%   16% 26% 27%   host
```

The three trailing percentages are the 1, 5 and 15 minute load averages expressed as a share of your core count, so 100% means the machine is exactly saturated.
