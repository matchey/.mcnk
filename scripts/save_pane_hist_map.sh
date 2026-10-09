#!/bin/bash
#
# tmux-resurrect post-save hook: record a "pane coordinate -> history uuid" map
# so that restore.sh can re-inject each pane's history id (see
# ~/.mcnk/bashrc/functions/resurrect_pane_hist.sh).
#
# Each pane's uuid is kept in the pane option @histfile_id (set by the shell on
# startup). The map key is "session:window_index.pane_index", which tmux-resurrect
# reconstructs identically on restore.

set -u

# Mirror tmux-resurrect's own directory resolution (scripts/helpers.sh) so the
# map always lands where restore.sh looks for it, even if @resurrect-dir is set.
resurrect_dir() {
  local dir
  dir="$(tmux show-option -gqv @resurrect-dir 2>/dev/null)"
  if [ -z "$dir" ]; then
    if [ -d "$HOME/.tmux/resurrect" ]; then
      dir="$HOME/.tmux/resurrect"
    else
      dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
    fi
  else
    # upstream expands ~, $HOME and $HOSTNAME inside @resurrect-dir
    dir="$(printf '%s' "$dir" | sed "s,\$HOME,$HOME,g; s,\$HOSTNAME,$(hostname),g; s,~,$HOME,g")"
  fi
  printf '%s' "$dir"
}

RESURRECT_DIR="$(resurrect_dir)"
MAP_FILE="$RESURRECT_DIR/pane_hist_map"
HIST_DIR="$HOME/.bash_history.d"
TAB=$'\t'

mkdir -p "$RESURRECT_DIR"

tmp="$(mktemp "$RESURRECT_DIR/.pane_hist_map.XXXXXX" 2>/dev/null)" || exit 0

# key<TAB>uuid, skipping panes that have no id yet.
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}${TAB}#{@histfile_id}" 2>/dev/null \
  | awk -F"$TAB" 'NF==2 && $2!=""' > "$tmp"

mv -f "$tmp" "$MAP_FILE"

# Conservative housekeeping: remove per-pane history files that are no longer
# referenced by any live pane AND are older than 30 days (never touches active
# panes or the non-tmux fallback file).
if [ -d "$HIST_DIR" ]; then
  live="$(awk -F"$TAB" '{print $2}' "$MAP_FILE" 2>/dev/null)"
  find "$HIST_DIR" -maxdepth 1 -type f -mtime +30 -print 2>/dev/null | while read -r f; do
    id="$(basename "$f")"
    [ "$id" = "no_tmux" ] && continue
    printf '%s\n' "$live" | grep -qxF "$id" || \rm -f "$f"
  done
fi
