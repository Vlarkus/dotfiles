#!/usr/bin/env bash
# Generates the tmux cheat-sheet shown by `prefix ?` (rendered with `less -R`).
# Re-run after changing bindings:  bash gen-cheatsheet.sh
# Colors live in the $'\033[..m' vars (no raw escape bytes in this source).
#
# Alignment rule: printf pads by BYTES, so any multibyte glyph (arrows, box
# rules) must go ONLY in the trailing UNPADDED field or a header line.
out="${1:-$HOME/.config/tmux/cheatsheet.txt}"

T=$'\033[1;33m'   # title
H=$'\033[1;35m'   # section header
K=$'\033[1;36m'   # keys
D=$'\033[90m'     # dim
R=$'\033[0m'
BAR='──────────────────────────────────────────────────────────────'

{
printf '\n'
printf '   %stmux cheat sheet%s      prefix = %s Ctrl-a %s   press prefix, then a key        %sq quits%s\n\n' \
       "$T" "$R" "$K" "$R" "$D" "$R"

hdr(){ printf '   %s%s %s%s\n' "$H" "$1" "$2" "$R"; }
# row: left-key  left-desc   right-key  right-desc(unpadded, multibyte OK here)
row(){ printf '     %s%-7s%s %-26s  %s%-9s%s %s\n' "$K" "$1" "$R" "$2" "$K" "$3" "$R" "$4"; }
one(){ printf '     %s%-7s%s %s\n' "$K" "$1" "$R" "$2"; }

hdr 'PANES' "${BAR}"
row '|'     'split right'              'h j k l' 'move focus  ← ↓ ↑ →'
row '-'     'split down'               'H J K L' 'resize (hold to repeat)'
row '\'     'split right, full height' 'z'       'zoom / unzoom'
row '_'     'split down, full width'   'x'       'close pane'
row 'Space' 'cycle layouts'            '{  }'    'swap with prev / next'
row 'b'     'break pane to a window'   '@'       'join another pane here'
row 'e'     'sync typing to all panes' 'q'       'show pane numbers'
printf '\n'

hdr 'WINDOWS' "  (tabs along the top) ${BAR:0:44}"
row 'c'     'new window'               'Alt-1..9' 'jump to window N (no prefix)'
row 'Tab'   'last window'              'C-h C-l'  'previous / next window'
row ','     'rename window'            '<   >'    'move window left / right'
one 'X'     'close window (asks first)'
printf '\n'

hdr 'SESSIONS' "  (projects / separate terminals) ${BAR:0:30}"
row 's'     'pick session/window tree' '(   )'    'previous / next session'
row 'C-c'   'new session'              'd'        'detach (keeps running)'
row 'R'     'rename session'           'Q'        'kill session (asks first)'
printf '\n'

hdr 'COPY & SCROLL' "${BAR:0:52}"
one 'v'     'enter copy mode  —  then, with NO prefix:'
printf '        %sv%s start selection    %sy%s / %sEnter%s copy    %s/%s %s?%s search    %sEsc%s leave\n' \
       "$K" "$R" "$K" "$R" "$K" "$R" "$K" "$R" "$K" "$R" "$K" "$R"
one 'p'     'paste last copy'
one 'mouse' 'wheel scrolls · drag selects & copies'
printf '\n'

hdr 'SURVIVES REBOOT / QUIT' "${BAR:0:44}"
row 'C-s'   'save all sessions now'    ''  'auto-saves every 5 min'
row 'C-r'   'restore saved sessions'   ''  'auto-restores on tmux start'
printf '\n'

hdr 'MISC' "${BAR}"
row 'r'     'reload tmux config'       ':'   'command prompt'
row '?'     'this help'                'C-?' 'full raw key list'
printf '\n'
printf '   %spress  q  to close%s\n' "$D" "$R"
} > "$out"
