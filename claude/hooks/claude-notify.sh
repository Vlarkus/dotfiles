#!/usr/bin/env bash
# Claude Code attention notifier (visual + audio).
# Usage: claude-notify.sh <done|attention|fail>
# Reads the hook's JSON payload on stdin.
#
# All notifications are TEMPORARY (normal urgency = auto-dismiss on KDE).
# Color cue via emoji + matching icon:  green=done  orange=attention  red=fail
#
# ── When does ORANGE (attention) fire? ────────────────────────────────────────
# We only want "attention" when Claude actually needs input — NOT the annoying
# 60s idle ping that Claude Code sends after it's already done.
#
#   Notification hook  -> only when notification_type means "needs input"
#                         (permission_prompt / elicitation_dialog / agent_needs_input).
#                         The idle_prompt (60s-after-done) type is dropped.
#   Stop hook (done)   -> upgraded to ORANGE if Claude's last message ends in a
#                         question (i.e. it stopped to ask YOU something).
#
# Caveat: the AskUserQuestion options-picker fires NO hook in Claude Code v2.1.x,
# so it can't be caught here. Prose questions (turn ends with "?") are caught via
# the Stop hook's last_assistant_message.
#
# To change a sound: audition with `sound-shop`, then edit the SND_* paths below.

kind="${1:-attention}"
input="$(cat)"

ntype="$(printf '%s' "$input" | jq -r '.notification_type // empty' 2>/dev/null)"
lastmsg="$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null)"

# True if the text ends with a question (allowing trailing markdown/closers).
is_question(){
  local s="$1" c
  s="${s%"${s##*[![:space:]]}"}"                       # trim trailing whitespace
  while [ -n "$s" ]; do                                # peel trailing */_/`/"/)/]/'
    c="${s: -1}"
    case "$c" in
      '*'|'_'|'`'|'"'|')'|']'|"'") s="${s:0:${#s}-1}"; s="${s%"${s##*[![:space:]]}"}" ;;
      *) break ;;
    esac
  done
  [ "${s: -1}" = "?" ]
}

# ── Decide whether to notify, and with what color ─────────────────────────────
case "$kind" in
  attention)
    # Notification hook: suppress the idle-after-done ping; only ping on real input needs.
    case "$ntype" in
      permission_prompt|elicitation_dialog|agent_needs_input) : ;;
      *) exit 0 ;;
    esac
    ;;
  done)
    # Stop hook: if Claude ended by asking the user something, make it ORANGE.
    if is_question "$lastmsg"; then kind="attention"; fi
    ;;
esac

dir="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
dir="${dir:-$PWD}"
proj="$(basename "$dir")"

# Which session to look at: the Claude chat name (tmux pane title #T),
# stripped of the leading spinner glyph. Falls back to the project dir.
label=""
if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
  label="$(tmux display-message -p -t "$TMUX_PANE" '#T' 2>/dev/null \
            | sed 's/^[^[:alnum:]]*//; s/[[:space:]]*$//')"
fi
[ -z "$label" ] && label="$proj"

SND="$HOME/.claude/sounds"

# ── Sound choices per category (change these after shopping with `sound-shop`) ──
# Custom synthesized cues live in ~/.claude/sounds (regenerate: gen-sounds.py).
SND_DONE="$SND/done-marimba.wav"
SND_ATTENTION="$SND/attn-marimba3.wav"
SND_FAIL="$SND/fail-marimba.wav"

case "$kind" in
  done)
    title="🟢 Claude finished"
    icon="dialog-positive"
    sound="$SND_DONE"
    ;;
  fail)
    title="🔴 Claude failed"
    icon="dialog-error"
    sound="$SND_FAIL"
    ;;
  attention|*)
    title="🟠 Claude needs you"
    icon="dialog-warning"
    sound="$SND_ATTENTION"
    ;;
esac

# Bottom line: the chat name (which session to look at)
body="$label"

# Visual: temporary desktop notification (normal urgency -> auto-dismisses)
notify-send -a "Claude Code" -u normal -i "$icon" "$title" "$body" 2>/dev/null

# Audio
[ -f "$sound" ] && paplay "$sound" 2>/dev/null

exit 0
