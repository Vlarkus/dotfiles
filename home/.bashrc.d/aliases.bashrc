# ~/.bashrc.d/aliases.bashrc
# Auto-sourced by ~/.bashrc (loops over ~/.bashrc.d/*)

# --- System / dnf (Fedora) ---
alias update='sudo dnf upgrade --refresh'
alias install='sudo dnf install'
alias remove='sudo dnf remove'
alias search='dnf search'
alias autoremove='sudo dnf autoremove'

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
command -v claude-launch    >/dev/null 2>&1 && alias cl='claude-launch'      # Claude launcher TUI
command -v dictate-settings >/dev/null 2>&1 && alias ds='dictate-settings'   # dictation settings
command -v console-font     >/dev/null 2>&1 && alias cf='console-font'       # TTY/ly font picker
