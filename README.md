# dotfiles

Fedora + KDE Plasma (Wayland) setup: bash, LazyVim, tmux, Alacritty, Claude Code,
and a local whisper.cpp dictation pipeline.

Files live here and are **symlinked** into `$HOME`, so editing the real config
edits the repo — just `git add -p && git commit`.

## New machine

```bash
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh            # symlink configs into $HOME (backs up anything it replaces)
./bootstrap.sh          # packages, keyd, ydotoold, console font, KDE settings
exec bash               # reload shell
```

Optional (not run by default — one compiles, one swaps your login manager):

```bash
./bootstrap.sh whisper  # build whisper.cpp + download models (dictation)
./bootstrap.sh ly       # replace the graphical login with the ly TUI
./bootstrap.sh --list   # see all sections
```

Then:
- `nvim` → LazyVim installs plugins from `lazy-lock.json` (exact pinned versions)
- `tmux` → `prefix + I` → TPM installs resurrect/continuum

`./install.sh --dry` shows what it would do without touching anything.

## What's here

| Path | Goes to | What |
|---|---|---|
| `home/.bashrc` | `~/.bashrc` | shell + `cl` launcher alias |
| `home/.bashrc.d/aliases.bashrc` | `~/.bashrc.d/` | aliases (`v` `ff` `lg` `ds` `cf` …) |
| `home/.inputrc` | `~/.inputrc` | cmd-style Tab completion cycling |
| `config/nvim/` | `~/.config/nvim` | LazyVim |
| `config/tmux/` | `~/.config/tmux/` | tmux.conf (prefix `C-a`) + cheatsheet (`prefix ?`) |
| `config/alacritty/` | `~/.config/alacritty/` | terminal (JetBrainsMono NF, Catppuccin) |
| `config/dictate/config` | `~/.config/dictate/` | whisper model / typing speed |
| `bin/` | `~/.local/bin/` | `claude-launch` `console-font` `dictate-*` `sound-shop` `tmux-attach` |
| `claude/` | `~/.claude/` | settings, statusline, notification hooks |
| `system/` | (reference) | keyd, ydotoold, vconsole — applied by `bootstrap.sh` |

**Not in this repo, by design:** `~/.claude/.credentials.json`, session/project
history, caches, tmux plugins, nvim plugin binaries, and `uv`/`uvx`/`claude`
(installed tools). Nothing here contains a secret.

## Custom bits worth knowing

- **`cl`** — TUI launcher for Claude Code (new session w/ model+permission options, or resume by name).
- **`cf`** — console-font picker. This panel is 4K/15.6" (~282 DPI) so the stock
  8×16 TTY font is unreadable; `vconsole.conf` sets `latarcyrheb-sun32`.
- **Dictation** — Right Ctrl (remapped to F23 by keyd) toggles `dictate-toggle`:
  records → whisper.cpp → types via ydotool. Tune with `ds`.
- **Claude notifications** — green = finished, orange = needs your input
  (fires when Claude's last message is a question), red = failed. The 60s
  "idle" ping is deliberately suppressed.

## Manual steps bootstrap can't do

- Bind **F23 → `dictate-toggle`** in System Settings → Keyboard → Shortcuts.
- Log into `gh` (`gh auth login`) and Claude Code (`claude`).
- Install JetBrainsMono Nerd Font if the terminal shows tofu.
