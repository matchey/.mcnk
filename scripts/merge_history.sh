#!/bin/bash
#
# Merge bash history files into one stream on stdout, deduplicated keep-last:
# when a command appears more than once, only its last occurrence (across all
# files, in argument order) is kept, so later files take precedence and
# recently used commands stay near the end (Up-arrow / Ctrl-r order).
#
# Entries are "#<epoch>" timestamp lines followed by the command (possibly
# multi-line); untimed lines are each treated as a separate entry.
# Missing/unreadable files are skipped.
#
# With -x EXCL, EXCL is merged last (so it wins every duplicate) but its own
# entries are not printed: the output is "FILE... minus anything in EXCL".
#
# Usage: merge_history.sh [-x EXCL] FILE...

excl=""
if [ "${1:-}" = "-x" ]; then
  excl="${2:-}"
  shift 2
fi

files=()
for f in "$@"; do
  [ -r "$f" ] && files+=("$f")
done
[ ${#files[@]} -eq 0 ] && exit 0
[ -n "$excl" ] && [ -r "$excl" ] && files+=("$excl") || excl=""

awk -v excl="$excl" '
  function emit() {
    if (!have) return
    have = 0
    if (cmd ~ /^[[:space:]]*$/) return
    n++; tss[n] = ts; cmds[n] = cmd; hidden[n] = in_excl; last[cmd] = n
  }
  # Keep untimed lines at a file head from being absorbed into the previous
  # file'"'"'s last entry.
  FNR == 1 { emit(); in_excl = (excl != "" && FILENAME == excl) }
  /^#[0-9]+$/ { emit(); ts = $0 "\n"; cmd = ""; have = 1; next }
  {
    if (have) { cmd = cmd $0 "\n"; next }
    ts = ""; cmd = $0 "\n"; have = 1; emit()
  }
  END {
    emit()
    for (i = 1; i <= n; i++)
      if (last[cmds[i]] == i && !hidden[i]) printf "%s%s", tss[i], cmds[i]
  }
' "${files[@]}"
