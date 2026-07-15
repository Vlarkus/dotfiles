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
alias ds='dictate-settings'

# Console/TTY font size picker (ly + TTYs)
alias cf='console-font'
