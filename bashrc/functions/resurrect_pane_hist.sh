#
# Per-pane bash history for tmux + tmux-resurrect.
#
# Each tmux pane gets a stable uuid (stored in the pane option @histfile_id) and
# its own HISTFILE (~/.bash_history.d/<uuid>), so Ctrl-r / Ctrl-p show only that
# pane's own history. The uuid survives tmux-resurrect save/restore: on restore,
# tmux-resurrect's scripts/restore.sh injects it via $RESURRECT_HISTFILE_ID.
#
# The dedup'd archive (~/.bash_history_uniq) keeps working unchanged: on every
# prompt the new history lines are appended to both the pane HISTFILE and the
# archive, and save_history_uniq.sh (EXIT trap) still compacts it by size.

# interactive shells only
case $- in
  *i*) ;;
  *) return 2>/dev/null || exit ;;
esac

__RESURRECT_HIST_DIR="$HOME/.bash_history.d"
__RESURRECT_HIST_ARCHIVE="$HOME/.bash_history_uniq"
mkdir -p "$__RESURRECT_HIST_DIR"

# Resolve this pane's history id (restore-injected env > pane option > new uuid).
__resurrect_hist_id() {
  if [ -n "$RESURRECT_HISTFILE_ID" ]; then
    printf '%s' "$RESURRECT_HISTFILE_ID"
    return
  fi
  local id
  id="$(tmux show -pqv ${TMUX_PANE:+-t "$TMUX_PANE"} @histfile_id 2>/dev/null)"
  if [ -n "$id" ]; then
    printf '%s' "$id"
    return
  fi
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen
  else
    cat /proc/sys/kernel/random/uuid
  fi
}

if [ -n "$TMUX" ]; then
  __rhist_id="$(__resurrect_hist_id)"
  # Persist on the pane so future resurrect saves can capture it.
  # `-t "$TMUX_PANE"` is mandatory: without an explicit target, `set -p` /
  # `show -pqv` resolve to the *session's current pane*, not the calling one, so
  # every shell spawned during bulk pane creation (byobu startup, resurrect
  # restore) would write its uuid onto window 0 and share a single HISTFILE.
  tmux set -p ${TMUX_PANE:+-t "$TMUX_PANE"} @histfile_id "$__rhist_id" 2>/dev/null
  export HISTFILE="$__RESURRECT_HIST_DIR/$__rhist_id"
  # bash already read the default HISTFILE at startup; swap to this pane's.
  # `builtin` is mandatory: bash_aliases defines `alias history='history | less
  # -SFRX +G'` and this file is sourced *after* it, so a bare `history -c` would
  # expand to `history | less -SFRX +G -c`. That leaves less' `~` filler lines on
  # the pane and silently skips loading the history.
  builtin history -c
  [ -r "$HISTFILE" ] && builtin history -r "$HISTFILE"
  unset __rhist_id
fi
unset -f __resurrect_hist_id
unset RESURRECT_HISTFILE_ID

# Per-prompt: flush new history lines to the (pane) HISTFILE and the archive.
# `history -a` writes only lines entered since the last append, so this never
# duplicates and never re-writes lines loaded via `history -r`.
__resurrect_hist_tmp="${TMPDIR:-/tmp}/.resurrect_hist.$$"
__resurrect_hist_sync() {
  : > "$__resurrect_hist_tmp" 2>/dev/null || return
  builtin history -a "$__resurrect_hist_tmp"
  [ -s "$__resurrect_hist_tmp" ] || return
  [ -n "$HISTFILE" ] && cat "$__resurrect_hist_tmp" >> "$HISTFILE"
  cat "$__resurrect_hist_tmp" >> "$__RESURRECT_HIST_ARCHIVE"
}
case ";${PROMPT_COMMAND};" in
  *";__resurrect_hist_sync;"*) ;;
  *) PROMPT_COMMAND="__resurrect_hist_sync${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac
