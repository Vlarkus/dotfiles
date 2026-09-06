# Minimal alt-screen TUI. Pure bash: this is the script that installs node, so
# it cannot depend on node — which rules out reusing sv's or cl's tui layer.
#
# Vocabulary follows the tui-design skill: [key] label for actions, ▌ for the
# row cursor, colour for state, and exactly one thing inverted at a time.

_R=$'\e[0m'; _DIM=$'\e[90m'; _HI=$'\e[1;36m'; _OK=$'\e[32m'; _W=$'\e[1m'; _INV=$'\e[7m'

# The UI goes to /dev/tty, never to stdout: tui_pick is called inside $( ),
# so stdout is a pipe carrying the answer. Drawing there would both capture
# the escape codes and leave the user staring at a blank screen.
tui_tty()     { { : >/dev/tty; } 2>/dev/null; }
tui_enter()   { printf '\e[?1049h\e[?25l' >/dev/tty; }
tui_restore() { printf '\e[?25h\e[?1049l' >/dev/tty; }
tui_home()    { printf '\e[H' >/dev/tty; }
# Redraw from the top and clear to the end, so frames never leave debris.
tui_render()  { { tui_home; local l; for l in "$@"; do printf '%s\e[K\n' "$l"; done; printf '\e[J'; } >/dev/tty; }
tui_key() {
  local k r; IFS= read -rsn1 k </dev/tty
  [ "$k" = $'\e' ] && { IFS= read -rsn2 -t 0.005 r </dev/tty; k+="$r"; }
  printf '%s' "$k"
}

# tui_pick "Title" name:label:state ...  -> prints the names that were selected.
# state is 1 (pre-checked) or 0. A name of "--" makes the label a heading:
# it is drawn, but never checked and never landed on by the cursor.
tui_pick() {
  local title="$1"; shift
  local -a names=() labels=() on=() sel=()
  local item
  for item in "$@"; do
    names+=("${item%%:*}")
    local rest="${item#*:}"
    labels+=("${rest%:*}")
    on+=("${rest##*:}")
    [ "${item%%:*}" = "--" ] || sel+=($(( ${#names[@]} - 1 )))
  done
  local n=${#names[@]} ns=${#sel[@]} c=0

  # No TTY (a pipe, CI): take the defaults rather than hanging on read.
  if ! tui_tty; then
    local i; for i in "${sel[@]}"; do [ "${on[$i]}" = 1 ] && printf '%s\n' "${names[$i]}"; done
    return
  fi

  tui_enter; trap tui_restore EXIT
  while :; do
    local -a out=("" "  ${_W}${title}${_R}")
    local i
    for i in $(seq 0 $((n-1))); do
      if [ "${names[$i]}" = "--" ]; then
        out+=("" "  ${_DIM}${labels[$i]}${_R}")
        continue
      fi
      local mark="[ ]"; [ "${on[$i]}" = 1 ] && mark="${_OK}[x]${_R}"
      if [ "$i" = "${sel[$c]}" ]; then
        out+=("  ${_HI}▌${_R}${mark} ${_W}${labels[$i]}${_R}")
      else
        out+=("   ${mark} ${_DIM}${labels[$i]}${_R}")
      fi
    done
    out+=("" "  ${_HI}[space]${_R}${_DIM} toggle  ${_R}${_HI}[a]${_R}${_DIM} all  ${_R}${_HI}[n]${_R}${_DIM} none  ${_R}${_HI}[enter]${_R}${_DIM} install  ${_R}${_HI}[q]${_R}${_DIM} cancel${_R}")
    tui_render "${out[@]}"

    case "$(tui_key)" in
      j|$'\e[B') c=$(( (c+1) % ns )) ;;
      k|$'\e[A') c=$(( (c-1+ns) % ns )) ;;
      ' ')       i=${sel[$c]}; on[$i]=$(( 1 - ${on[$i]} )) ;;
      a)         for i in "${sel[@]}"; do on[$i]=1; done ;;
      n)         for i in "${sel[@]}"; do on[$i]=0; done ;;
      q)         tui_restore; trap - EXIT; return 1 ;;
      '')        break ;;
    esac
  done
  tui_restore; trap - EXIT
  local i; for i in "${sel[@]}"; do [ "${on[$i]}" = 1 ] && printf '%s\n' "${names[$i]}"; done
  return 0
}
