# dotfiles

The **hub**: one repo to configure a Linux machine. It carries the basic configs
— bash, LazyVim, tmux, Alacritty, Claude Code — and knows how to fetch the tools,
which live in repos of their own. Built on Fedora + KDE Plasma (Wayland);
`bootstrap.sh` also supports **Ubuntu/Debian**.

Configs live here and are **symlinked** into `$HOME`, so editing the real config
edits the repo — just `git add -p && git commit`.

```
        dotfiles  ──  install.sh  ──┬── configs   symlinked from this repo
         (hub)                      │
                                    └── spokes    cloned from their own repos
                                        sv · cl · dictate · skills
```

## New machine

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh            # menu: tick the configs and tools you want
./bootstrap.sh          # git, tmux, neovim, ripgrep/fd/fzf, lazygit, fastfetch + TPM
exec bash
```

`./install.sh` with no arguments opens a menu — `j`/`k` to move, `space` to
toggle, `enter` to install. It is pure bash on purpose: this is the script that
installs Node, so it cannot need Node to draw itself. Run it without a terminal
(a pipe, CI) and it takes the defaults instead of hanging.

Non-interactive forms:

| | |
|---|---|
| `./install.sh core` | bash + tmux + LazyVim, nothing else |
| `./install.sh all` | every config group |
| `./install.sh tools` | just the spokes |
| `./install.sh --list` | everything available, from disk |
| `./install.sh --dry` | full run, changes nothing |

## Spokes — the tools

Each tool is its own repo. `spokes.d/*.spoke` is only the hub's note of where to
find it; the contract is the one they already satisfied — **an `install.sh` at
the root that accepts `--check`**. The hub clones it, fast-forwards it if it is
already there (never a reset — local edits fail loudly instead of vanishing),
runs the installer, and prints that `--check` back to you as the confirmation.

| Spoke | What |
|---|---|
| [`sv`](https://github.com/Vlarkus/sv) | server control panel — power modes, screen, services |
| [`cl`](https://github.com/Vlarkus/claude-launcher) | Claude Code launcher TUI |
| [`dictate`](https://github.com/Vlarkus/dictate) | push-to-talk speech to text |
| `skills` | Claude skills (private) |

Anything needing root prints the `sudo` line rather than running it, so the menu
never holds a password prompt. Adding a spoke is adding a file to `spokes.d/`.

`bootstrap.sh` detects the distro and papers over the differences:

| | Fedora | Ubuntu/Debian |
|---|---|---|
| packages | `dnf` | `apt` |
| **neovim** | repo is current | **Ubuntu 24.04 and older**: apt's is too old for LazyVim (needs **≥ 0.11.2**) → falls back to `ppa:neovim-ppa/unstable`, then the official static build. **Ubuntu 25.10+ ships 0.11.6 in plain apt** — no PPA needed. |
| **lazygit** | in repo | **24.04 and older**: not in apt → `ppa:lazygit-team/release`, then the GitHub release binary. **25.10+: in plain apt.** |
| **fastfetch** | in repo | **24.04 and older**: `ppa:zhangsongcui3371/fastfetch`. **25.10+: in plain apt.** |
| **fd** | `fd` | binary is `fdfind` → symlinked to `fd` so LazyVim finds it |
| **7-zip** | `p7zip` | package is `7zip` (`p7zip-full` is gone on 25.10+) |
| console font | `/etc/vconsole.conf` | `/etc/default/console-setup` + `setupcon` |
| Caps→Ctrl | KDE `kxkbrc` | GNOME `gsettings` + `/etc/default/keyboard` for the TTY |
| terminal | Alacritty | Alacritty, or Ptyxis (GNOME default since 25.10) — same palette either way |
| `ly` | in repo | not packaged → skipped |

The PPA fallbacks are still there and still correct for older releases — they just
no longer trigger on a current Ubuntu.

Then:
- `nvim` → LazyVim installs plugins from `lazy-lock.json` (exact pinned versions)
- `tmux` → resurrect/continuum are cloned by `bootstrap.sh` and load via `run-shell`

`./install.sh --dry` shows what it would do without touching anything.

## Full machine rebuild

```bash
./install.sh all        # every config group
./install.sh tools      # every spoke
./bootstrap.sh --list   # see all package sections
./bootstrap.sh pkgs console kde
./bootstrap.sh ly       # swap the login manager for the ly TUI
```

## What's here

| Path | Goes to | What |
|---|---|---|
| `home/.bashrc` | `~/.bashrc` | shell, PATH, `~/.bashrc.d/*` loader |
| `home/.bashrc.d/aliases.bashrc` | `~/.bashrc.d/` | aliases (`v` `ff` `lg` `ds` `cf` …) |
| `home/.inputrc` | `~/.inputrc` | cmd-style Tab completion cycling |
| `config/nvim/` | `~/.config/nvim` | LazyVim |
| `config/tmux/` | `~/.config/tmux/` | tmux.conf (prefix `C-a`) + cheatsheet (`prefix ?`) |
| `config/alacritty/alacritty.toml.in` | `~/.config/alacritty/alacritty.toml` | terminal (JetBrainsMono NF, Catppuccin) — **rendered, not linked**: TOML has no `$HOME`, so `@HOME@` is substituted at install |
| `config/ptyxis/` | `~/.local/share/org.gnome.Ptyxis/palettes/` | same Catppuccin Mocha colours for GNOME's Ptyxis (`bootstrap.sh kde` selects it) |
| `bin/` | `~/.local/bin/` | `console-font` `tmux-attach` |
| `claude/` | `~/.claude/` | settings, statusline, notification hooks |
| `system/` | (reference) | vconsole — applied by `bootstrap.sh` |

**Not in this repo, by design:** `~/.claude/.credentials.json`, session/project
history, caches, tmux plugins, nvim plugin binaries, and `uv`/`uvx`/`claude`
(installed tools). Nothing here contains a secret.

## Custom bits worth knowing

- **`cl`** — Claude Code launcher TUI, installed as a spoke. Deliberately *not*
  aliased here, so nothing shadows its shim on `PATH`.
- **`cf`** — console-font picker. Detects the panel (resolution from DRM,
  physical size from EDID) and the distro's font directory. This laptop is
  4K/15.6" (~286 DPI), where the stock 8×16 TTY font is unreadable, so
  `vconsole.conf` sets `latarcyrheb-sun32`.
- **Claude notifications** — green = finished, orange = needs your input
  (fires when Claude's last message is a question), red = failed. The 60s
  "idle" ping is deliberately suppressed.

## Manual steps bootstrap can't do

- Log into `gh` (`gh auth login`) and Claude Code (`claude`).
- Install JetBrainsMono Nerd Font if the terminal shows tofu.

## Layout

```
install.sh        menu + dispatch
bootstrap.sh      packages, fonts, KDE, ly
lib/tui.sh        the menu renderer (pure bash)
lib/spoke.sh      clone / update / install a spoke
spokes.d/*.spoke  where each tool lives
home/ config/ bin/ claude/ system/    the configs themselves
```
