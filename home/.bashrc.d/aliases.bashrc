# ~/.bashrc.d/aliases.bashrc
# Auto-sourced by ~/.bashrc (loops over ~/.bashrc.d/*)

# --- System / package manager ------------------------------------------------
# Same five verbs on both distros; detected at shell startup so this file stays
# portable between the Fedora box and the Ubuntu one.
if command -v dnf >/dev/null 2>&1; then
  alias update='sudo dnf upgrade --refresh'
  alias install='sudo dnf install'
  alias remove='sudo dnf remove'
  alias search='dnf search'
  alias autoremove='sudo dnf autoremove'
elif command -v apt >/dev/null 2>&1; then
  alias update='sudo apt update && sudo apt upgrade'
  alias install='sudo apt install'
  alias remove='sudo apt remove'
  alias search='apt search'
  alias autoremove='sudo apt autoremove'
fi

# --- Better ls ---
alias ll='ls -lh'
alias la='ls -a'
alias lla='ls -lha'
alias l='ls -CF'

# --- Safety nets ---
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'

# --- Editor ---
alias v='nvim'

# --- Tools ---
alias ff='fastfetch'
alias lg='lazygit'

# --- Quality of life ---
alias cls='clear'
alias df='df -h'
alias free='free -h'
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias myip='curl -s ifconfig.me; echo'
alias ports='ss -tulpn'
alias reload='source ~/.bashrc'

# --- Optional tools ---------------------------------------------------------
# These scripts live in this repo's bin/ and are only linked by a full
# `install.sh` (not `install.sh core`). Guarded so a core-only machine doesn't
# get aliases that point at nothing.
# NOTE: no `cl` alias here on purpose. `cl` is now the claude-launcher shim
# (github.com/Vlarkus/claude-launcher -> ~/.local/bin/cl), which supersedes
# bin/claude-launch. An alias would shadow that shim wherever bin/ is linked.
command -v dictate-settings >/dev/null 2>&1 && alias ds='dictate-settings'   # dictation settings
command -v console-font     >/dev/null 2>&1 && alias cf='console-font'       # TTY/ly font picker
