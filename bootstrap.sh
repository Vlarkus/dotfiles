#!/usr/bin/env bash
# bootstrap.sh — the system-level half of this setup (the part dotfiles can't carry).
#
# Supports Fedora (dnf) and Ubuntu/Debian (apt). Run AFTER ./install.sh.
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
say(){  printf '\n\033[1;36m== %s\033[0m\n' "$*"; }
ok(){   printf '  \033[32m✓\033[0m %s\n' "$*"; }
note(){ printf '  \033[33m!\033[0m %s\n' "$*"; }
bad(){  printf '  \033[31m✗\033[0m %s\n' "$*"; }

# ── which distro are we on ───────────────────────────────────────────────────
ID=""; VERSION_ID=""
[ -r /etc/os-release ] && . /etc/os-release
if   command -v dnf     >/dev/null 2>&1; then FAMILY=fedora
elif command -v apt-get >/dev/null 2>&1; then FAMILY=debian
else bad "need dnf or apt — unsupported distro"; exit 1; fi

have(){ command -v "$1" >/dev/null 2>&1; }
pm_refresh(){ [ "$FAMILY" = debian ] && sudo apt-get update -qq || true; }
pm_install(){
  case "$FAMILY" in
    fedora) sudo dnf install -y "$@" ;;
    debian) sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" ;;
  esac
}
# add a PPA (ubuntu only); returns 1 if not possible
ppa(){
  [ "$ID" = ubuntu ] || return 1
  have add-apt-repository || pm_install software-properties-common || return 1
  sudo add-apt-repository -y "$1" >/dev/null 2>&1 && pm_refresh
}

# ── package names that differ between distros ────────────────────────────────
#            fedora            debian/ubuntu
# fd-find    fd-find           fd-find   (binary: fd     vs fdfind)
# ffmpeg     ffmpeg-free       ffmpeg
# c++        gcc-c++           g++
# tty fonts  terminus-fonts-console   console-setup
CORE_PKGS_fedora=(git tmux ripgrep fd-find fzf)
CORE_PKGS_debian=(git tmux ripgrep fd-find fzf curl)

EXTRA_PKGS_fedora=(gh alacritty jq keyd ydotool ffmpeg-free gcc-c++ cmake make python3 terminus-fonts-console)
EXTRA_PKGS_debian=(gh alacritty jq        ydotool ffmpeg      g++     cmake make python3 console-setup)
# note: keyd is NOT packaged for ubuntu/debian — see sec_keyd

# ── neovim: LazyVim needs >= 0.11.2, apt is frequently older ─────────────────
NVIM_MIN=0.11.2
nvim_version(){ nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1; }
nvim_ok(){
  local v; v="$(nvim_version)"; [ -n "$v" ] || return 1
  [ "$(printf '%s\n%s\n' "$NVIM_MIN" "$v" | sort -V | head -1)" = "$NVIM_MIN" ]
}
nvim_tarball(){   # distro-independent fallback: official static build
  say "neovim: installing official static build (apt's is too old)"
  local base=https://github.com/neovim/neovim/releases/latest/download
  local tgz
  for tgz in nvim-linux-x86_64.tar.gz nvim-linux64.tar.gz; do
    if curl -fsSL "$base/$tgz" -o /tmp/nvim.tgz 2>/dev/null; then
      rm -rf "$HOME/.local/share/nvim-static"
      mkdir -p "$HOME/.local/share/nvim-static"
      tar xzf /tmp/nvim.tgz -C "$HOME/.local/share/nvim-static" --strip-components=1 || continue
      mkdir -p "$HOME/.local/bin"
      ln -sfn "$HOME/.local/share/nvim-static/bin/nvim" "$HOME/.local/bin/nvim"
      rm -f /tmp/nvim.tgz
      return 0
    fi
  done
  return 1
}
ensure_nvim(){
  if nvim_ok; then ok "neovim $(nvim_version) (>= $NVIM_MIN)"; return; fi
  pm_install neovim 2>/dev/null || true
  if nvim_ok; then ok "neovim $(nvim_version) from packages"; return; fi
  note "packaged neovim is $(nvim_version || echo missing) — LazyVim needs >= $NVIM_MIN"
  if [ "$FAMILY" = debian ] && ppa ppa:neovim-ppa/unstable; then
    pm_install neovim && nvim_ok && { ok "neovim $(nvim_version) from neovim-ppa"; return; }
  fi
  nvim_tarball && nvim_ok && { ok "neovim $(nvim_version) (static build in ~/.local/bin)"; return; }
  bad "could not get neovim >= $NVIM_MIN — LazyVim will complain"
}

# ── lazygit: not in ubuntu/debian repos at all ───────────────────────────────
lazygit_binary(){
  local v url
  v="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
       | grep -oE '"tag_name": *"v[^"]+"' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  [ -n "$v" ] || return 1
  url="https://github.com/jesseduffield/lazygit/releases/download/v${v}/lazygit_${v}_Linux_x86_64.tar.gz"
  curl -fsSL "$url" -o /tmp/lg.tgz || return 1
  tar xzf /tmp/lg.tgz -C /tmp lazygit || return 1
  mkdir -p "$HOME/.local/bin"; install -m755 /tmp/lazygit "$HOME/.local/bin/lazygit"
  rm -f /tmp/lg.tgz /tmp/lazygit
}
ensure_lazygit(){
  have lazygit && { ok "lazygit present"; return; }
  case "$FAMILY" in
    fedora) pm_install lazygit && ok "lazygit" ;;
    debian)
      ppa ppa:lazygit-team/release && pm_install lazygit 2>/dev/null
      have lazygit || { lazygit_binary && ok "lazygit (github binary -> ~/.local/bin)"; }
      have lazygit || note "lazygit unavailable — the 'lg' alias will be inert"
      ;;
  esac
}

ensure_fastfetch(){
  have fastfetch && { ok "fastfetch present"; return; }
  case "$FAMILY" in
    fedora) pm_install fastfetch && ok "fastfetch" ;;
    debian)
      pm_install fastfetch 2>/dev/null
      have fastfetch || { ppa ppa:zhangsongcui3371/fastfetch && pm_install fastfetch; }
      have fastfetch && ok "fastfetch" || note "fastfetch unavailable — the 'ff' alias will be inert"
      ;;
  esac
}

# on debian the binary is `fdfind`; LazyVim/telescope look for `fd`
ensure_fd(){
  have fd && return
  if have fdfind; then
    mkdir -p "$HOME/.local/bin"; ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "linked fdfind -> ~/.local/bin/fd (LazyVim expects 'fd')"
  fi
}

# ── sections ─────────────────────────────────────────────────────────────────
sec_core(){
  say "core: bash + tmux + LazyVim  [$ID ${VERSION_ID:-} / $FAMILY]"
  pm_refresh
  local -n arr="CORE_PKGS_$FAMILY"
  pm_install "${arr[@]}" && ok "core packages"
  ensure_nvim
  ensure_fd
  ensure_lazygit
  ensure_fastfetch
  sec_tpm
}

sec_tpm(){
  say "tmux plugin manager"
  local t="$HOME/.config/tmux/plugins/tpm"
  if [ -d "$t" ]; then ok "tpm already present"
  else git clone -q https://github.com/tmux-plugins/tpm "$t" && ok "tpm cloned"; fi
  note "open tmux, then press: prefix + I   (installs resurrect/continuum)"
}

sec_pkgs(){
  say "packages (full)"
  pm_refresh
  local -n arr="EXTRA_PKGS_$FAMILY"
  pm_install "${arr[@]}" && ok "extra packages"
  [ "$FAMILY" = debian ] && note "keyd is not packaged on ubuntu/debian — run: ./bootstrap.sh keyd"
}

sec_keyd(){
  say "keyd (Right Ctrl -> F23 for the dictation hotkey)"
  if ! have keyd; then
    case "$FAMILY" in
      fedora) pm_install keyd ;;
      debian)
        note "keyd isn't in apt — building from source"
        pm_install build-essential git || return 1
        local s=/tmp/keyd-src; rm -rf "$s"
        git clone -q --depth=1 https://github.com/rvaiya/keyd "$s" || return 1
        make -C "$s" >/dev/null && sudo make -C "$s" install >/dev/null || { bad "keyd build failed"; return 1; }
        ;;
    esac
  fi
  sudo mkdir -p /etc/keyd
  sudo cp "$D/system/keyd-default.conf" /etc/keyd/default.conf
  sudo systemctl enable --now keyd && ok "keyd enabled"
  sudo keyd reload 2>/dev/null && ok "keyd reloaded"
}

sec_ydotool(){
  say "ydotoold (types dictated text)"
  have ydotoold || pm_install ydotool
  # the stored unit hardcodes uid 1000 — regenerate for THIS machine's user
  sudo tee /etc/systemd/system/ydotoold.service >/dev/null <<EOF
[Unit]
Description=ydotoold input daemon (root, user-owned socket)

[Service]
ExecStart=$(command -v ydotoold || echo /usr/bin/ydotoold) --socket-path=/run/ydotoold/socket --socket-own=$(id -u):$(id -g)
RuntimeDirectory=ydotoold
RuntimeDirectoryMode=0755
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now ydotoold && ok "ydotoold enabled (socket owned by $(id -u):$(id -g))"
}

sec_console(){
  say "console font (readable TTY/ly on HiDPI)"
  case "$FAMILY" in
    fedora)
      sudo cp "$D/system/vconsole.conf" /etc/vconsole.conf && ok "$(grep FONT /etc/vconsole.conf)"
      note "tweak anytime with:  cf   (console-font TUI)"
      ;;
    debian)
      # debian/ubuntu don't use vconsole.conf — it's console-setup + setupcon
      pm_install console-setup
      sudo sed -i -E 's|^#?\s*FONTFACE=.*|FONTFACE="Terminus"|; s|^#?\s*FONTSIZE=.*|FONTSIZE="16x32"|' \
        /etc/default/console-setup
      grep -q '^FONTFACE=' /etc/default/console-setup || echo 'FONTFACE="Terminus"' | sudo tee -a /etc/default/console-setup >/dev/null
      grep -q '^FONTSIZE=' /etc/default/console-setup || echo 'FONTSIZE="16x32"' | sudo tee -a /etc/default/console-setup >/dev/null
      sudo setupcon --force 2>/dev/null
      ok "console-setup: Terminus 16x32"
      note "the 'cf' TUI is Fedora-only (it writes /etc/vconsole.conf)"
      ;;
  esac
}

sec_kde(){
  say "KDE settings"
  if ! have kwriteconfig6; then note "KDE Plasma 6 not detected — skipping"; return; fi
  kwriteconfig6 --file kxkbrc --group Layout --key Options "ctrl:nocaps"
  kwriteconfig6 --file kxkbrc --group Layout --key ResetOldOptions "true"
  ok "Caps Lock -> Ctrl"
  kwriteconfig6 --file kwinrc --group EdgeBarrier --key EdgeBarrier 0
  kwriteconfig6 --file kwinrc --group EdgeBarrier --key CornerBarrier false
  ok "mouse edge barrier disabled"
  qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null
  note "dictation hotkey (F23) must be bound by hand:"
  note "  System Settings > Keyboard > Shortcuts > custom > command: dictate-toggle > key: Right Ctrl"
}

sec_whisper(){
  say "whisper.cpp (local dictation engine)"
  case "$FAMILY" in
    fedora) pm_install gcc-c++ cmake make git ;;
    debian) pm_install build-essential cmake git ;;
  esac
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

sec_ly(){
  say "ly (TUI login manager)"
  if [ "$FAMILY" != fedora ]; then
    note "ly isn't packaged for ubuntu/debian — skipping."
    note "build it yourself: https://github.com/fairyglade/ly"
    return
  fi
  pm_install ly || return 1
  local cur; cur="$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" 2>/dev/null)"
  [ -n "$cur" ] && [ "$cur" != "ly@tty2.service" ] && sudo systemctl disable "$cur" 2>/dev/null
  sudo systemctl enable ly@tty2.service && ok "ly enabled on tty2"
  note "revert:  sudo systemctl disable ly@tty2.service && sudo systemctl enable <old-dm> -f"
}

DEFAULT=(core)
ALL=(core pkgs tpm keyd ydotool console kde whisper ly)

if [ "${1:-}" = "--list" ]; then
  cat <<EOF
detected: ${ID:-?} ${VERSION_ID:-} (family: $FAMILY)

default:
  core      bash + tmux + LazyVim  (packages + tmux plugin manager)   <- runs if no args

full machine:
  pkgs      every package (alacritty, gh, jq, dictation, build deps)
  keyd      Right Ctrl -> F23 remap        (built from source on ubuntu)
  ydotool   ydotoold service (dictation types text)
  console   big TTY console font (HiDPI)
  kde       Caps Lock -> Ctrl, disable mouse edge barrier  (skipped if no KDE)
  whisper   build whisper.cpp + models     (compiles, slow)
  ly        ly TUI login manager           (fedora only)

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
echo "  reload shell:   exec bash"
echo "  nvim           -> LazyVim installs plugins from lazy-lock.json"
echo "  tmux, prefix+I -> TPM installs tmux plugins"
