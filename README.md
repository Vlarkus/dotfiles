# dotfiles

bash, LazyVim, tmux, Alacritty and Claude Code
pipeline. Built on Fedora + KDE Plasma (Wayland); `bootstrap.sh` also supports
**Ubuntu/Debian**.

Files live here and are **symlinked** into `$HOME`, so editing the real config
edits the repo — just `git add -p && git commit`.

## New machine — the short version

Bash + tmux + LazyVim, nothing else. Works on **Fedora** and **Ubuntu/Debian**:

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh core       # symlink bashrc/aliases, tmux, nvim
./bootstrap.sh          # git, tmux, neovim, ripgrep/fd/fzf, lazygit, fastfetch + TPM
exec bash
```

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

Only if you want the rest (alacritty, Claude Code setup, dictation, ly, KDE tweaks):

```bash
./install.sh            # symlink everything
./bootstrap.sh --list   # see all sections
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
| `config/alacritty/` | `~/.config/alacritty/` | terminal (JetBrainsMono NF, Catppuccin) |
| `config/ptyxis/` | `~/.local/share/org.gnome.Ptyxis/palettes/` | same Catppuccin Mocha colours for GNOME's Ptyxis (`bootstrap.sh kde` selects it) |
| `bin/` | `~/.local/bin/` | `console-font` `tmux-attach` |
| `claude/` | `~/.claude/` | settings, statusline, notification hooks |
| `system/` | (reference) | vconsole — applied by `bootstrap.sh` |

**Not in this repo, by design:** `~/.claude/.credentials.json`, session/project
history, caches, tmux plugins, nvim plugin binaries, and `uv`/`uvx`/`claude`
(installed tools). Nothing here contains a secret.

## Custom bits worth knowing

- **`cl`** — Claude Code launcher TUI. Lives in its own repo now
  (github.com/Vlarkus/claude-launcher); clone it and run `./install.sh` there.
  Deliberately *not* aliased here, so nothing shadows its shim.
- **`cf`** — console-font picker. This panel is 4K/15.6" (~282 DPI) so the stock
  8×16 TTY font is unreadable; `vconsole.conf` sets `latarcyrheb-sun32`.
- **Claude notifications** — green = finished, orange = needs your input
  (fires when Claude's last message is a question), red = failed. The 60s
  "idle" ping is deliberately suppressed.

## Manual steps bootstrap can't do

- Log into `gh` (`gh auth login`) and Claude Code (`claude`).
- Install JetBrainsMono Nerd Font if the terminal shows tofu.

## Dictation moved out

Push-to-talk speech-to-text now lives in its own repo, with the keyd remap, the
ydotool plumbing and the whisper.cpp build together instead of scattered across
three directories here:

    github.com/Vlarkus/dictate
