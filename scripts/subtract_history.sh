#!/bin/bash
#
# Print FILE minus the history entries in REMOVE, treating REMOVE as a multiset:
# each REMOVE entry deletes one matching FILE entry, the latest occurrence first
# (a session's own lines are the most recently appended ones). Entries match on
# their "#<epoch>" timestamp line plus full (possibly multi-line) command text,
# so the same command saved by another session at another time is kept.
# Untimed lines are each a separate entry, as in merge_history.sh. This differs
# from merge_history.sh, which dedups by command text alone.
#
# Usage: subtract_history.sh REMOVE FILE

if [ $# -ne 2 ]; then
  echo "usage: subtract_history.sh REMOVE FILE" >&2
  exit 2
fi

awk -v remove_file="$1" '
  function emit() {
    if (!have) return
    have = 0
    if (in_remove) { count[entry]++; return }
    n++; entries[n] = entry
  }
  FNR == 1 { emit(); in_remove = (FILENAME == remove_file) }
  /^#[0-9]+$/ { emit(); entry = $0 "\n"; have = 1; next }
  {
    if (have) { entry = entry $0 "\n"; next }
    entry = $0 "\n"; have = 1; emit()
  }
  END {
    emit()
    for (i = n; i >= 1; i--)
      if (count[entries[i]] > 0) { count[entries[i]]--; dropped[i] = 1 }
    for (i = 1; i <= n; i++)
      if (!dropped[i]) printf "%s", entries[i]
  }
' "$1" "$2"
