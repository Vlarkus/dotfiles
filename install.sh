#!/usr/bin/env bash
# install.sh — symlink these dotfiles into $HOME.
#
# Safe to re-run. Anything it would overwrite is moved to ~/.dotfiles-backup/<timestamp>/
# first, so this can never silently eat an existing config.
#
#   ./install.sh core     bash + tmux + LazyVim only   <- the stuff that matters
#   ./install.sh          everything (adds alacritty, claude, dictation configs)
#   ./install.sh --dry    show what it would do, change nothing
#
# Then: ./bootstrap.sh  (installs tmux/nvim/deps). Extras are opt-in there too.
set -uo pipefail

D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0; CORE=0
for a in "$@"; do
  case "$a" in
    --dry) DRY=1 ;;
    core)  CORE=1 ;;
  esac
done
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.dotfiles-backup/$STAMP"
n_link=0; n_same=0; n_back=0

link(){ # $1 = path inside repo   $2 = path relative to $HOME
  local src="$D/$1" dst="$HOME/$2"
  if [ ! -e "$src" ]; then echo "  skip (not in repo): $1"; return; fi

  # already pointing at the right place?
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    echo "  = $2"; n_same=$((n_same+1)); return
  fi

  if [ "$DRY" = 1 ]; then
    [ -e "$dst" ] && echo "  would back up + link: $2" || echo "  would link: $2"
    return
  fi

  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP/$(dirname "$2")"
    mv "$dst" "$BACKUP/$2" && { echo "  backed up: $2"; n_back=$((n_back+1)); }
  fi
  ln -sfn "$src" "$dst" && { echo "  ✓ $2"; n_link=$((n_link+1)); }
}

echo "== shell =="
link home/.bashrc                  .bashrc
link home/.inputrc                 .inputrc
link home/.bashrc.d/aliases.bashrc .bashrc.d/aliases.bashrc

echo "== nvim (LazyVim) + tmux =="
link config/nvim                .config/nvim
link config/tmux/tmux.conf      .config/tmux/tmux.conf
link config/tmux/cheatsheet.txt .config/tmux/cheatsheet.txt

if [ "$CORE" = 1 ]; then
  echo
  echo "core mode: bash + tmux + LazyVim only."
  echo "(skipped alacritty / claude / dictation — run without 'core' to link those too)"
  exit 0
fi

echo "== terminal / dictation =="
# Alacritty isn't on every machine, and isn't packaged the same everywhere.
# Only link its config where the binary exists, so a box that uses the distro's
# own terminal doesn't collect a config for something it can't run.
# Force it on with:  ALACRITTY=1 ./install.sh   (e.g. installing it later)
if [ "${ALACRITTY:-}" = 1 ] || command -v alacritty >/dev/null 2>&1; then
  link config/alacritty/alacritty.toml .config/alacritty/alacritty.toml
else
  echo "  skip (alacritty not installed): .config/alacritty/alacritty.toml"
  echo "    -> ALACRITTY=1 ./install.sh   to link it anyway"
fi
link config/dictate/config           .config/dictate/config
# Ptyxis (GNOME/Ubuntu default terminal): same Catppuccin Mocha colours as
# alacritty.toml. Harmless on machines without Ptyxis — it's just a file.
link config/ptyxis/Catppuccin-Mocha-Dotfiles.palette \
     .local/share/org.gnome.Ptyxis/palettes/Catppuccin-Mocha-Dotfiles.palette

echo "== scripts =="
for s in console-font dictate-settings dictate-toggle tmux-attach; do
  link "bin/$s" ".local/bin/$s"
done
[ "$DRY" = 0 ] && chmod +x "$D"/bin/* 2>/dev/null

echo "== claude (configs only; credentials/sessions are never in this repo) =="
link claude/settings.json          .claude/settings.json
link claude/statusline.sh          .claude/statusline.sh
link claude/hooks/claude-notify.sh .claude/hooks/claude-notify.sh
link claude/hooks/gen-sounds.py    .claude/hooks/gen-sounds.py
[ "$DRY" = 0 ] && chmod +x "$D"/claude/statusline.sh "$D"/claude/hooks/*.sh 2>/dev/null

echo
if [ "$DRY" = 1 ]; then
  echo "dry run — nothing changed."
else
  echo "linked: $n_link   already ok: $n_same   backed up: $n_back"
  [ "$n_back" -gt 0 ] && echo "backups -> $BACKUP"
  cat <<'EOF'

Next:
  1. ./bootstrap.sh              # packages + keyd + ydotoold + fonts + KDE
  2. exec bash                   # reload shell
  3. nvim                        # LazyVim installs plugins from lazy-lock.json
  4. tmux                        # resurrect/continuum load automatically
EOF
fi
