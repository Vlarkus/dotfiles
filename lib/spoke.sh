# Spokes: the tools that live in their own repos.
#
# The contract is deliberately not a new manifest format — it is the one both
# existing tools already satisfy: a spoke has install.sh at its root, and that
# script accepts --check. Nothing had to change in sv, cl or dictate to qualify.
#
# A .spoke file is only the hub's knowledge of where to find it:
#
#   name=         menu key
#   title=        menu label
#   repo=         clone URL
#   dir=          where it lives ($SRC_ROOT expands)
#   needs=        commands that must exist first, space separated
#   install=      run for the user half   (default: ./install.sh if present)
#   root_install= exists -> print the sudo line; never run sudo from the menu
#   link_dirs=    symlink each top-level dir of the repo into this path
#                 (the plugin-directory pattern — how ~/.claude/skills works)

SPOKE_DIR="${SPOKE_DIR:-$D/spokes.d}"
SRC_ROOT="${SRC_ROOT:-$HOME/Documents/GitHub}"

spoke_field() { sed -n "s/^$2=//p" "$1" | head -1; }
# Fields may reference $SRC_ROOT / $HOME. Expand those without running the value.
spoke_path()  { local v; v=$(spoke_field "$1" "$2"); [ -n "$v" ] && eval printf '%s' "\"$v\""; }

spoke_list() { local f; for f in "$SPOKE_DIR"/*.spoke; do [ -e "$f" ] && printf '%s\n' "$f"; done; }

spoke_install() {
  local f="$1" name title repo dir needs cmd n d base
  name=$(spoke_field "$f" name)
  title=$(spoke_field "$f" title)
  repo=$(spoke_field "$f" repo)
  dir=$(spoke_path  "$f" dir)
  needs=$(spoke_field "$f" needs)

  echo "== $title =="
  for n in $needs; do
    command -v "$n" >/dev/null || { echo "  skip: needs '$n', which is not installed"; return 0; }
  done

  if [ -d "$dir/.git" ]; then
    if [ "${DRY:-0}" = 1 ]; then echo "  would update $dir"; else
      # Fast-forward only. A spoke with local edits should fail loudly here
      # rather than have them silently discarded by a reset.
      git -C "$dir" pull --ff-only -q 2>/dev/null && echo "  updated $dir" \
        || echo "  could not fast-forward $dir (local changes?) — left alone"
    fi
  elif [ "${DRY:-0}" = 1 ]; then
    echo "  would clone $repo -> $dir"; return 0
  else
    mkdir -p "$(dirname "$dir")"
    # Never block on a credential prompt: a private spoke should say so and
    # move on, not hang inside an alt-screen with no visible cause.
    if GIT_TERMINAL_PROMPT=0 git clone -q "$repo" "$dir" 2>/dev/null; then
      echo "  cloned -> $dir"
    else
      echo "  clone failed — private repo? try: gh auth login"; return 0
    fi
  fi

  cmd=$(spoke_field "$f" install)
  # A repo may ship install.sh without the +x bit (claude-launcher does).
  # Falling back to `sh` beats silently installing nothing.
  [ -z "$cmd" ] && [ -f "$dir/install.sh" ] && \
    { [ -x "$dir/install.sh" ] && cmd=./install.sh || cmd='sh ./install.sh'; }
  if [ -n "$cmd" ]; then
    if [ "${DRY:-0}" = 1 ]; then echo "  would run: (cd $dir && $cmd)"
    else ( cd "$dir" && eval "$cmd" >/dev/null 2>&1 ) && echo "  installed" \
         || echo "  install reported a problem — run it by hand: (cd $dir && $cmd)"
    fi
  fi

  d=$(spoke_path "$f" link_dirs)
  if [ -n "$d" ]; then
    [ "${DRY:-0}" = 1 ] || mkdir -p "$d"
    for base in "$dir"/*/; do
      base=$(basename "$base")
      case "$base" in .*|docs|_template) continue ;; esac
      if [ "${DRY:-0}" = 1 ]; then echo "  would link $d/$base"
      else ln -sfn "$dir/$base" "$d/$base" && echo "  linked $d/$base"; fi
    done
  fi

  [ -n "$(spoke_field "$f" root_install)" ] && echo "  needs root for the rest:  sudo $dir/install.sh"
  [ "${DRY:-0}" = 1 ] || { [ -n "$cmd" ] && ( cd "$dir" && eval "$cmd" --check 2>/dev/null | sed 's/^/  /' ); }
  return 0
}
