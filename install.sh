#!/usr/bin/env bash
# install.sh — symlink these dotfiles into $HOME.
#
# Safe to re-run. Anything it would overwrite is moved to ~/.dotfiles-backup/<timestamp>/
# first, so this can never silently eat an existing config.
#
#   ./install.sh          pick what to install, from a menu
#   ./install.sh all      every config group, no menu
#   ./install.sh core     bash + tmux + LazyVim only   <- the stuff that matters
#   ./install.sh tools    just the tool repos (sv, cl, dictate, skills)
#   ./install.sh --list   show every group and tool, change nothing
#   ./install.sh --dry    show what it would do, change nothing
#
# Config groups live here. Tools live in their own repos and are cloned on
# demand — see spokes.d/. Then: ./bootstrap.sh for packages.
set -uo pipefail

D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$D/lib/tui.sh"
. "$D/lib/spoke.sh"

DRY=0; CORE=0; MODE=menu; PICK=()
for a in "$@"; do
  case "$a" in
    --dry)  DRY=1 ;;
    core)   CORE=1; MODE=all ;;
    all)    MODE=all ;;
    tools)  MODE=tools ;;
    --list) MODE=list ;;
    menu)   MODE=menu ;;
    # A bare name selects just that group or spoke: `./install.sh editor sv`
    -*)     echo "unknown option: $a  (try --list)" >&2; exit 2 ;;
    *)      PICK+=("$a"); MODE=pick ;;
  esac
done
# A pipe or a script gets the old behaviour; only an interactive run gets a menu.
[ "$MODE" = menu ] && { tui_tty || MODE=all; }
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

render(){ # $1 = template inside repo   $2 = path relative to $HOME
  # For formats with no variable expansion of their own. TOML is the reason
  # this exists: alacritty.toml cannot say $HOME, so the path must be baked in.
  local src="$D/$1" dst="$HOME/$2" tmp
  if [ ! -e "$src" ]; then echo "  skip (not in repo): $1"; return; fi
  tmp=$(mktemp)
  sed -e "s|@HOME@|$HOME|g" -e "s|@USER@|$USER|g" "$src" > "$tmp"

  if [ -f "$dst" ] && cmp -s "$tmp" "$dst"; then
    echo "  = $2"; n_same=$((n_same+1)); rm -f "$tmp"; return
  fi
  if [ "$DRY" = 1 ]; then
    [ -e "$dst" ] && echo "  would back up + render: $2" || echo "  would render: $2"
    rm -f "$tmp"; return
  fi

  mkdir -p "$(dirname "$dst")"
  # A rendered file is a copy, not a symlink — so back up whatever is there,
  # including the symlink an older install.sh left behind.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP/$(dirname "$2")"
    mv "$dst" "$BACKUP/$2" && { echo "  backed up: $2"; n_back=$((n_back+1)); }
  fi
  mv "$tmp" "$dst" && chmod 644 "$dst" && { echo "  ✓ $2 (rendered)"; n_link=$((n_link+1)); }
}

grp_shell(){
echo "== shell =="
link home/.bashrc                  .bashrc
link home/.inputrc                 .inputrc
link home/.bashrc.d/aliases.bashrc .bashrc.d/aliases.bashrc
}

grp_editor(){
echo "== nvim (LazyVim) + tmux =="
link config/nvim                .config/nvim
link config/tmux/tmux.conf      .config/tmux/tmux.conf
link config/tmux/cheatsheet.txt .config/tmux/cheatsheet.txt
}

grp_terminal(){
echo "== terminal =="
# Alacritty isn't on every machine, and isn't packaged the same everywhere.
# Only link its config where the binary exists, so a box that uses the distro's
# own terminal doesn't collect a config for something it can't run.
# Force it on with:  ALACRITTY=1 ./install.sh   (e.g. installing it later)
if [ "${ALACRITTY:-}" = 1 ] || command -v alacritty >/dev/null 2>&1; then
  render config/alacritty/alacritty.toml.in .config/alacritty/alacritty.toml
else
  echo "  skip (alacritty not installed): .config/alacritty/alacritty.toml"
  echo "    -> ALACRITTY=1 ./install.sh   to link it anyway"
fi
# Ptyxis (GNOME/Ubuntu default terminal): same Catppuccin Mocha colours as
# alacritty.toml. Harmless on machines without Ptyxis — it's just a file.
link config/ptyxis/Catppuccin-Mocha-Dotfiles.palette \
     .local/share/org.gnome.Ptyxis/palettes/Catppuccin-Mocha-Dotfiles.palette
}

grp_scripts(){
echo "== scripts =="
for s in console-font tmux-attach; do
  link "bin/$s" ".local/bin/$s"
done
[ "$DRY" = 0 ] && chmod +x "$D"/bin/* 2>/dev/null
}

grp_claude(){
echo "== claude (configs only; credentials/sessions are never in this repo) =="
link claude/settings.json          .claude/settings.json
link claude/statusline.sh          .claude/statusline.sh
link claude/hooks/claude-notify.sh .claude/hooks/claude-notify.sh
link claude/hooks/gen-sounds.py    .claude/hooks/gen-sounds.py
[ "$DRY" = 0 ] && chmod +x "$D"/claude/statusline.sh "$D"/claude/hooks/*.sh 2>/dev/null
}

# ── what exists ──────────────────────────────────────────────────────
CONF_GROUPS=(shell:"shell — bashrc, aliases, inputrc"
        editor:"editor — LazyVim + tmux"
        terminal:"terminal — alacritty, ptyxis palette"
        scripts:"scripts — console-font, tmux-attach"
        claude:"claude — settings, statusline, hooks")

if [ "$MODE" = list ]; then
  echo "config groups:"
  for g in "${CONF_GROUPS[@]}"; do printf "  %-10s %s\n" "${g%%:*}" "${g#*:}"; done
  echo
  echo "tools (own repos, cloned on demand):"
  for f in $(spoke_list); do printf '  %-10s %s\n' "$(spoke_field "$f" name)" "$(spoke_field "$f" title)"; done
  exit 0
fi

DID_CONF=1   # cleared when the run touched no config group
run_groups(){ local g; for g in "$@"; do "grp_$g"; done; }
run_spokes(){ local n f; for n in "$@"; do
  f="$D/spokes.d/$n.spoke"; [ -e "$f" ] && spoke_install "$f"
done; }

case "$MODE" in
  all)
    if [ "$CORE" = 1 ]; then
      run_groups shell editor
      echo; echo "core mode: bash + tmux + LazyVim only."
    else
      run_groups shell editor terminal scripts claude
    fi
    ;;
  pick)
    gsel=(); ssel=()
    for c in "${PICK[@]}"; do
      if [ "$(type -t "grp_$c")" = function ]; then gsel+=("$c")
      elif [ -e "$D/spokes.d/$c.spoke" ]; then ssel+=("$c")
      else echo "unknown: $c  (try --list)" >&2; exit 2; fi
    done
    [ ${#gsel[@]} -gt 0 ] && run_groups "${gsel[@]}" || DID_CONF=0
    [ ${#ssel[@]} -gt 0 ] && run_spokes "${ssel[@]}"
    ;;
  tools)
    DID_CONF=0
    for f in $(spoke_list); do spoke_install "$f"; done
    ;;
  menu)
    items=("--:configs — linked from this repo:0")
    for g in "${CONF_GROUPS[@]}"; do items+=("${g%%:*}:${g#*:}:1"); done
    items+=("--:tools — cloned from their own repos:0")
    for f in $(spoke_list); do
      n=$(spoke_field "$f" name)
      # Pre-check a tool only if it is already here — a fresh machine should
      # opt in to a 1.6 GB model download, not have it chosen for it.
      d=$(spoke_path "$f" dir)
      items+=("spoke_$n:$(spoke_field "$f" title):$([ -d "$d/.git" ] && echo 1 || echo 0)")
    done
    chosen=$(tui_pick "dotfiles — choose what to install" "${items[@]}") || { echo "cancelled"; exit 0; }
    [ -z "$chosen" ] && { echo "nothing selected"; exit 0; }
    gsel=(); ssel=()
    for c in $chosen; do
      case "$c" in spoke_*) ssel+=("${c#spoke_}") ;; *) gsel+=("$c") ;; esac
    done
    [ ${#gsel[@]} -gt 0 ] && run_groups "${gsel[@]}" || DID_CONF=0
    [ ${#ssel[@]} -gt 0 ] && run_spokes "${ssel[@]}"
    ;;
esac

echo
if [ "$DRY" = 1 ]; then
  echo "dry run — nothing changed."
elif [ "$DID_CONF" = 1 ]; then
  echo "linked: $n_link   already ok: $n_same   backed up: $n_back"
  [ "$n_back" -gt 0 ] && echo "backups -> $BACKUP"
  cat <<'EOF'

Next:
  1. ./bootstrap.sh              # packages + fonts + KDE
  2. exec bash                   # reload shell
  3. nvim                        # LazyVim installs plugins from lazy-lock.json
  4. tmux                        # resurrect/continuum load automatically
EOF
fi
