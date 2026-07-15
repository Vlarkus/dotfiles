#!/usr/bin/env bash
# Claude Code status line. Receives session JSON on stdin, prints one line.
# Segments:  dir  branch │ model │ ctx% │ cost │ 5h-reset │ 5h-used%

input="$(cat)"
j() { printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null; }

# ── data ──
dir="$(j '.workspace.current_dir')"; [ -z "$dir" ] && dir="$(j '.cwd')"; [ -z "$dir" ] && dir="$PWD"
proj="$(basename "$dir")"
model="$(j '.model.display_name')"
branch="$(git -C "$dir" branch --show-current 2>/dev/null)"
ctx="$(j '.context_window.used_percentage')"
cost="$(j '.cost.total_cost_usd')"
reset5="$(j '.rate_limits.five_hour.resets_at')"
rl5pct="$(j '.rate_limits.five_hour.used_percentage')"

# ── colors (Catppuccin Mocha, truecolor) ──
R=$'\e[0m'
BLUE=$'\e[38;2;137;180;250m';  MAUVE=$'\e[38;2;203;166;247m'
GREEN=$'\e[38;2;166;227;161m'; RED=$'\e[38;2;243;139;168m'
YELL=$'\e[38;2;249;226;175m';  PEACH=$'\e[38;2;250;179;135m'
GRAY=$'\e[38;2;127;132;156m';  TEAL=$'\e[38;2;148;226;213m'

# ── glyphs ──
I_DIR=$''; I_GIT=$''; I_AI=$'\U000f06a9'
I_CTX=$''; I_COST=$''; I_TIME=$''; I_RST=$''
SEP="  ${GRAY}│${R}  "
I_USE=''   # pie (5h limit used %)
I_COST=''  # money (total cost)

# ── helpers ──
pct_color() { local p=${1%.*}; if [ "${p:-0}" -ge 80 ]; then printf '%s' "$RED"; elif [ "${p:-0}" -ge 50 ]; then printf '%s' "$YELL"; else printf '%s' "$GREEN"; fi; }
fmt_until() { local d=$(( ${1:-0} - $(date +%s) )) h m; [ $d -lt 0 ] && d=0; h=$((d/3600)); m=$(((d%3600)/60));
  if [ $h -gt 0 ]; then printf '%dh %dm' $h $m; else printf '%dm' $m; fi; }

# ── assemble ──
out="${BLUE}${I_DIR} ${proj}${R}"
[ -n "$branch" ] && out="${out}  ${GRAY}${I_GIT} ${GREEN}${branch}${R}"
[ -n "$model" ]  && out="${out}${SEP}${MAUVE}${I_AI} ${model}${R}"
[ -n "$ctx" ]    && out="${out}${SEP}$(pct_color "$ctx")${I_CTX} $(printf '%.0f' "$ctx")%${R}"
[ -n "$cost" ]   && out="${out}${SEP}${TEAL}$(printf '$%.2f' "$cost")${R}"
[ -n "$reset5" ] && out="${out}${SEP}${PEACH}${I_RST} $(fmt_until "$reset5")${R}"
[ -n "$rl5pct" ] && out="${out}${SEP}$(pct_color "$rl5pct")${I_USE} $(printf '%.0f' "$rl5pct")%${R}"

printf '%s' "$out"
