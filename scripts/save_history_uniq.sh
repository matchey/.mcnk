#!/bin/bash

# Save this session's new history into the dedup'd archive (~/.bash_history_uniq)
# and keep the normal HISTFILE updated.
#
# Design (append-only + size-thresholded, lock-guarded compaction):
#   - Extract new session lines to a PID-unique temp file (no shared temp file).
#   - Append them to HISTFILE and to the archive. Appends are atomic (O_APPEND),
#     so closing many shells at once (e.g. all tmux/byobu panes) never corrupts
#     or loses history.
#   - Only when the archive grows past a size threshold, and only while holding
#     an exclusive lock, dedup it in place (keep-first) to bound its size.
# This replaces the previous read-modify-write + shared-temp + `history -w`
# approach, which raced (duplication, ballooning, lost updates) under concurrent
# shell exits.

outfile="$HOME/.bash_history_uniq"
lockfile="$HOME/.bash_history_uniq.lock"
threshold=524288   # 512KB: compact only once the archive grows beyond this

tmpfile="$(mktemp "${TMPDIR:-/tmp}/bash_history_uniq.$$.XXXXXX" 2>/dev/null)"
if [ -z "$tmpfile" ]; then
  return 2>&- || exit
fi

# Extract this session's not-yet-saved history lines (bypass the `history` alias).
# Normally the per-prompt hook (__resurrect_hist_sync) has already flushed these,
# so this only captures the final command(s) entered since the last prompt. Even
# when there is nothing new, we still fall through to the size-based compaction
# below so the archive stays bounded.
builtin history -a "$tmpfile"

have_new=0
[ -s "$tmpfile" ] && have_new=1

# Keep the normal history file updated (append only; O_APPEND is concurrency-safe).
if [ "$have_new" -eq 1 ] && [ -n "$HISTFILE" ]; then
  cat "$tmpfile" >> "$HISTFILE"
fi

# Update the archive under an exclusive lock so a concurrent compaction can't lose
# these lines. If the lock can't be taken within the timeout, fall back to a plain
# append (still atomic and never corrupts; a later run compacts any duplicates).
{
  if flock -w 2 9; then
    [ "$have_new" -eq 1 ] && cat "$tmpfile" >> "$outfile"
    size="$(wc -c < "$outfile" 2>/dev/null)"
    if [ "${size:-0}" -gt "$threshold" ]; then
      ctmp="$(mktemp "${TMPDIR:-/tmp}/bash_history_uniq_compact.$$.XXXXXX" 2>/dev/null)"
      if [ -n "$ctmp" ]; then
        awk '
          function emit() {
            if (!have) return
            if (cmd ~ /^[[:space:]]*$/) return
            if (cmd in seen) return
            seen[cmd] = 1; print ts; printf "%s", cmd
          }
          /^#[0-9]+$/ { emit(); ts = $0; cmd = ""; have = 1; next }
          { if (!have) { print; next } cmd = cmd $0 "\n" }
          END { emit() }
        ' "$outfile" > "$ctmp" && [ -s "$ctmp" ] && \mv -f "$ctmp" "$outfile" || \rm -f "$ctmp"
      fi
    fi
  else
    [ "$have_new" -eq 1 ] && cat "$tmpfile" >> "$outfile"
  fi
} 9>"$lockfile"

\rm -f "$tmpfile"

