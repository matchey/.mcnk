#!/bin/bash
#
# One-shot repair for panes whose shells started before the per-pane history
# fixes landed (see ~/.mcnk/bashrc/functions/resurrect_pane_hist.sh).
#
# Those shells ran `tmux set -p @histfile_id` without an explicit target, so all
# panes of a session wrote onto window 0 and ended up sharing one HISTFILE.
# This script gives every pane its own uuid and asks the *bash* panes to
# re-source the function so they pick it up. Panes running anything other than
# bash are skipped: re-sourcing needs an idle prompt to type into.
#
# Usage:
#   bash ~/.mcnk/scripts/backfill_pane_hist_id.sh          # dry run (default)
#   bash ~/.mcnk/scripts/backfill_pane_hist_id.sh --apply  # actually do it

set -u

FUNC_FILE="$HOME/.mcnk/bashrc/functions/resurrect_pane_hist.sh"
APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

if [ -z "${TMUX:-}" ] && ! tmux has-session 2>/dev/null; then
  echo "no tmux server found" >&2
  exit 1
fi

new_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen
  else
    cat /proc/sys/kernel/random/uuid
  fi
}

TAB=$'\t'
skipped=0
patched=0
ok=0
declare -A claimed=()

while IFS="$TAB" read -r pane_id key cmd hist_id; do
  [ -n "$pane_id" ] || continue

  # A pane is healthy only if it owns an id no other pane claims. Shared ids are
  # exactly what the old bug produced, so keep the first claimant and re-issue
  # for the rest.
  if [ -n "$hist_id" ] && [ -z "${claimed[$hist_id]:-}" ]; then
    claimed[$hist_id]=1
    echo "ok     $key ($hist_id)"
    ok=$((ok + 1))
    continue
  fi

  if [ "$cmd" != "bash" ]; then
    echo "skip   $key ($cmd is running)"
    skipped=$((skipped + 1))
    continue
  fi

  uuid="$(new_uuid)"
  claimed[$uuid]=1
  echo "patch  $key -> $uuid"
  patched=$((patched + 1))

  if [ "$APPLY" -eq 1 ]; then
    tmux set -p -t "$pane_id" @histfile_id "$uuid" || continue
    # Re-source in the pane: the function reads @histfile_id for *this* pane,
    # repoints HISTFILE and reloads it. Its PROMPT_COMMAND guard makes the
    # re-source idempotent.
    tmux send-keys -t "$pane_id" "source '$FUNC_FILE'" Enter
  fi
done < <(tmux list-panes -a -F "#{pane_id}${TAB}#{session_name}:#{window_index}.#{pane_index}${TAB}#{pane_current_command}${TAB}#{@histfile_id}")

echo
echo "panes patched: $patched, already ok: $ok, skipped: $skipped"
if [ "$APPLY" -eq 0 ]; then
  echo "(dry run - re-run with --apply to perform the changes)"
else
  echo "now refresh the map: bash ~/.mcnk/scripts/save_pane_hist_map.sh"
fi
