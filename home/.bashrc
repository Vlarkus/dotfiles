# .bashrc
# Aliases live in ~/.bashrc.d/aliases.bashrc (sourced by the loop at the bottom).
#
# Cross-distro: works on Fedora (/etc/bashrc) and Ubuntu/Debian (/etc/bash.bashrc).
# The Debian-flavoured blocks below (lesspipe, debian_chroot, dircolors,
# bash_completion) are all guarded, so they're simply skipped on Fedora.

# If not running interactively, don't do anything
case $- in
  *i*) ;;
    *) return;;
esac

# Source global definitions
if [ -f /etc/bashrc ]; then
  . /etc/bashrc          # Fedora / RHEL
elif [ -f /etc/bash.bashrc ]; then
  . /etc/bash.bashrc     # Ubuntu / Debian
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
  PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# ── History ──────────────────────────────────────────────────────────────────
HISTCONTROL=ignoreboth      # no dupes, no lines starting with a space
shopt -s histappend         # append, don't clobber
HISTSIZE=10000
HISTFILESIZE=20000

# ── Shell behaviour ──────────────────────────────────────────────────────────
shopt -s checkwinsize       # keep LINES/COLUMNS correct after each command
# shopt -s globstar         # uncomment to make ** recurse

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ── Prompt ───────────────────────────────────────────────────────────────────
# identify the chroot you're working in (Debian; used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
  xterm-color|*-256color|alacritty) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm-alike, set the window title to user@host:dir
case "$TERM" in
  xterm*|rxvt*|alacritty)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# ── Color support for ls ─────────────────────────────────────────────────────
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
fi

# Alias for long-running commands:  sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# ── Completion ───────────────────────────────────────────────────────────────
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ── User aliases and functions ───────────────────────────────────────────────
# Last, so ~/.bashrc.d/* wins over anything defined above.
if [ -d ~/.bashrc.d ]; then
  for rc in ~/.bashrc.d/*; do
    if [ -f "$rc" ]; then
      . "$rc"
    fi
  done
fi
unset rc
