#!/usr/bin/env bash
# bootstrap.sh — the system-level half of this setup (the part dotfiles can't carry).
#
# Run AFTER ./install.sh. Targets Fedora (dnf) + KDE Plasma / Wayland.
# Sections are independent and idempotent.
#
#   ./bootstrap.sh                  # 'core' only: bash + tmux + LazyVim
#   ./bootstrap.sh pkgs keyd kde    # pick specific sections
#   ./bootstrap.sh --list           # show every section
#
# Default is deliberately just 'core'. The machine-rebuild sections (dictation,
# keyd, console font, KDE tweaks, ly, whisper) are all opt-in.
set -uo pipefail

D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
say(){ printf '\n\033[1;36m== %s\033[0m\n' "$*"; }
ok(){  printf '  \033[32m✓\033[0m %s\n' "$*"; }
note(){ printf '  \033[33m!\033[0m %s\n' "$*"; }

# Just enough for bash + tmux + LazyVim (the stuff that actually matters).
CORE_PKGS=(
  git tmux neovim
  ripgrep fd-find fzf                 # LazyVim needs these to search
  fastfetch lazygit                   # the `ff` / `lg` aliases
)

# Everything else, for a full machine rebuild.
FULL_PKGS=(
  "${CORE_PKGS[@]}" gh alacritty jq
  keyd ydotool                        # key remap + input injection (dictation)
  ffmpeg-free                         # dictation recording
  gcc-c++ cmake make                  # whisper.cpp build
  python3                             # gen-sounds.py
  terminus-fonts-console              # big TTY fonts (4K screens)
)

sec_core(){
  say "core: bash + tmux + LazyVim"
  sudo dnf install -y "${CORE_PKGS[@]}" && ok "core packages installed"
  sec_tpm
}

sec_pkgs(){
  say "packages (full)"
  sudo dnf install -y "${FULL_PKGS[@]}" && ok "packages installed"
}

sec_tpm(){
  say "tmux plugin manager"
  local t="$HOME/.config/tmux/plugins/tpm"
  if [ -d "$t" ]; then ok "tpm already present"
  else git clone -q https://github.com/tmux-plugins/tpm "$t" && ok "tpm cloned"; fi
  note "open tmux, then press: prefix + I   (installs resurrect/continuum)"
}

sec_keyd(){
  say "keyd (Right Ctrl -> F23 for dictation hotkey)"
  sudo mkdir -p /etc/keyd
  sudo cp "$D/system/keyd-default.conf" /etc/keyd/default.conf
  sudo systemctl enable --now keyd && ok "keyd enabled"
  sudo keyd reload 2>/dev/null && ok "keyd reloaded"
}

sec_ydotool(){
  say "ydotoold (types dictated text)"
  # NOTE: the stored unit hardcodes uid 1000; regenerate for THIS machine's user.
  sudo tee /etc/systemd/system/ydotoold.service >/dev/null <<EOF
[Unit]
Description=ydotoold input daemon (root, user-owned socket)

[Service]
ExecStart=/usr/bin/ydotoold --socket-path=/run/ydotoold/socket --socket-own=$(id -u):$(id -g)
RuntimeDirectory=ydotoold
RuntimeDirectoryMode=0755
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now ydotoold && ok "ydotoold enabled (socket owned by $(id -u):$(id -g))"
  grep -q YDOTOOL_SOCKET "$HOME/.bashrc.d/aliases.bashrc" 2>/dev/null \
    || note 'if dictation cannot type, export YDOTOOL_SOCKET=/run/ydotoold/socket'
}

sec_console(){
  say "console font (readable TTY/ly on HiDPI)"
  sudo cp "$D/system/vconsole.conf" /etc/vconsole.conf && ok "$(grep FONT /etc/vconsole.conf)"
  note "tweak anytime with:  cf   (console-font TUI)"
}

sec_kde(){
  say "KDE settings"
  # Caps Lock -> Ctrl
  kwriteconfig6 --file kxkbrc --group Layout --key Options "ctrl:nocaps"
  kwriteconfig6 --file kxkbrc --group Layout --key ResetOldOptions "true"
  ok "Caps Lock -> Ctrl"
  # Stop the pointer sticking at screen edges between monitors
  kwriteconfig6 --file kwinrc --group EdgeBarrier --key EdgeBarrier 0
  kwriteconfig6 --file kwinrc --group EdgeBarrier --key CornerBarrier false
  ok "mouse edge barrier disabled"
  qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
  note "dictation hotkey (F23) must be bound by hand:"
  note "  System Settings > Keyboard > Shortcuts > add custom > command: dictate-toggle > key: Right Ctrl"
}

sec_whisper(){   # optional, compiles from source
  say "whisper.cpp (local dictation engine)"
  local w="$HOME/.local/share/whisper.cpp"
  if [ -d "$w/.git" ]; then ok "already cloned"; else
    git clone -q https://github.com/ggml-org/whisper.cpp "$w" || return 1
  fi
  cmake -S "$w" -B "$w/build" -DCMAKE_BUILD_TYPE=Release >/dev/null \
    && cmake --build "$w/build" -j"$(nproc)" --config Release >/dev/null \
    && ok "built"
  for m in tiny.en base.en small.en; do
    [ -f "$w/models/ggml-$m.bin" ] || (cd "$w" && bash ./models/download-ggml-model.sh "$m" >/dev/null 2>&1 && ok "model $m")
  done
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$w/build/bin/whisper-cli" "$HOME/.local/bin/whisper-cli" && ok "whisper-cli linked"
}

sec_ly(){        # optional, swaps the login manager
  say "ly (TUI login manager)"
  sudo dnf install -y ly || return 1
  local cur; cur="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" 2>/dev/null)"
  [ -n "$cur" ] && [ "$cur" != "ly@tty2.service" ] && sudo systemctl disable "$cur" 2>/dev/null
  sudo systemctl enable ly@tty2.service && ok "ly enabled on tty2"
  note "revert:  sudo systemctl disable ly@tty2.service && sudo systemctl enable <old-dm> -f"
}

DEFAULT=(core)
ALL=(core pkgs tpm keyd ydotool console kde whisper ly)

if [ "${1:-}" = "--list" ]; then
  cat <<'EOF'
default:
  core      bash + tmux + LazyVim  (packages + tmux plugin manager)   <- runs if no args

full machine:
  pkgs      every package (adds alacritty, gh, jq, dictation, build deps)
  keyd      Right Ctrl -> F23 remap
  ydotool   ydotoold service (dictation types text)
  console   big TTY/ly console font (HiDPI)
  kde       Caps Lock -> Ctrl, disable mouse edge barrier
  whisper   build whisper.cpp + models   (compiles, slow)
  ly        replace login manager with ly TUI

  ./bootstrap.sh                 # core only
  ./bootstrap.sh pkgs kde        # pick sections
EOF
  exit 0
fi

RUN=("$@"); [ $# -eq 0 ] && RUN=("${DEFAULT[@]}")
for s in "${RUN[@]}"; do
  case "$s" in
    core) sec_core ;; pkgs) sec_pkgs ;; tpm) sec_tpm ;; keyd) sec_keyd ;; ydotool) sec_ydotool ;;
    console) sec_console ;; kde) sec_kde ;; whisper) sec_whisper ;; ly) sec_ly ;;
    *) note "unknown section: $s" ;;
  esac
done

say "done"
echo "  reload shell:  exec bash"
echo "  nvim          -> LazyVim installs plugins from lazy-lock.json"
echo "  tmux, prefix+I -> TPM installs tmux plugins"
