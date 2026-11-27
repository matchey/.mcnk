#
# Per-pane bash history for tmux + tmux-resurrect, and for Herdr.
#
# Each tmux pane gets a stable uuid (stored in the pane option @histfile_id) and
# its own HISTFILE (~/.bash_history.d/<uuid>). In Herdr (which strips $TMUX from
# pane environments) the pane-hist plugin of ~/.herdr maps the restored pane id
# to ~/.bash_history.d/herdr/<uuid> instead. On startup the shell loads the
# shared archive followed by that pane's own history (deduplicated keep-last), so
# a new pane starts with all history while the pane's own commands come first on
# Ctrl-r / Ctrl-p. The uuid survives tmux-resurrect save/restore: on restore,
# tmux-resurrect's scripts/restore.sh injects it via $RESURRECT_HISTFILE_ID.
#
# The dedup'd archive (~/.bash_history_uniq) keeps working unchanged: on every
# prompt the new history lines are appended to both the pane HISTFILE and the
# archive, and save_history_uniq.sh (EXIT trap) still compacts it by size.
# Because lines are persisted at once, the `history` function below makes
# `history -c` / `history -d` also remove this shell's lines from both files.

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

__RESURRECT_HERDR_HELPER="$HOME/.herdr/plugins/pane-hist/pane-hist"

# The innermost multiplexer wins: Herdr unsets $TMUX in its panes, and tmux in a
# Herdr pane sets it again.
__rhist_file=
if [ -n "$TMUX" ]; then
  __rhist_id="$(__resurrect_hist_id)"
  # Persist on the pane so future resurrect saves can capture it.
  # `-t "$TMUX_PANE"` is mandatory: without an explicit target, `set -p` /
  # `show -pqv` resolve to the *session's current pane*, not the calling one, so
  # every shell spawned during bulk pane creation (byobu startup, resurrect
  # restore) would write its uuid onto window 0 and share a single HISTFILE.
  tmux set -p ${TMUX_PANE:+-t "$TMUX_PANE"} @histfile_id "$__rhist_id" 2>/dev/null
  __rhist_file="$__RESURRECT_HIST_DIR/$__rhist_id"
elif [ -n "$HERDR_PANE_ID" ] && [ -x "$__RESURRECT_HERDR_HELPER" ]; then
  # Resolved once: a pane moved later keeps this shell but gets a new pane id,
  # and the plugin rekeys the map so the file stays with the pane.
  __rhist_file="$("$__RESURRECT_HERDR_HELPER" histfile)" ||
    echo "resurrect_pane_hist: pane-hist failed; using the default HISTFILE" >&2
fi

if [ -n "$__rhist_file" ]; then
  export HISTFILE="$__rhist_file"
  # bash loads $HISTFILE *after* the startup files, so at startup it will load
  # this pane's file by itself; we only prepend the shared archive minus the
  # pane's entries (keep-last), so a new pane is not empty and Up-arrow still
  # reaches the pane's own commands first. When re-sourced later (e.g. by
  # backfill_pane_hist_id.sh) bash won't reload, so load the pane file here too.
  # A merged temp file keeps HISTFILE as the pane file; `history -a` never
  # re-writes lines loaded via `history -r`.
  # `builtin` is mandatory: bash_aliases defines `alias history='history | less
  # -SFRX +G'` and this file is sourced *after* it, so a bare `history -c` would
  # expand to `history | less -SFRX +G -c`. That leaves less' `~` filler lines on
  # the pane and silently skips loading the history.
  builtin history -c
  __rhist_tmp="$(mktemp "${TMPDIR:-/tmp}/.resurrect_hist_load.$$.XXXXXX" 2>/dev/null)"
  if [ -n "$__rhist_tmp" ] && \
     "$HOME/.mcnk/scripts/merge_history.sh" -x "$HISTFILE" "$__RESURRECT_HIST_ARCHIVE" > "$__rhist_tmp"; then
    builtin history -r "$__rhist_tmp"
  fi
  [ -n "$__rhist_tmp" ] && \rm -f "$__rhist_tmp"
  # Not exported: a nested bash is a fresh startup and must take the first path.
  if [ -n "${__RESURRECT_HIST_STARTED:-}" ] && [ -r "$HISTFILE" ]; then
    builtin history -r "$HISTFILE"
  fi
  __RESURRECT_HIST_STARTED=1
fi
unset __rhist_id __rhist_tmp __rhist_file __RESURRECT_HERDR_HELPER
unset -f __resurrect_hist_id
unset RESURRECT_HISTFILE_ID

# Shared with save_history_uniq.sh: every append and rewrite of the archive or a
# pane HISTFILE holds this lock, so a rewrite's `mv` can't drop a concurrent
# append.
__RESURRECT_HIST_LOCK="$HOME/.bash_history_uniq.lock"

# Entries this shell has flushed to disk, kept in memory only so `history -c/-d`
# can retract them (see `history` below). Reset on (re-)source: the list was
# just cleared and reloaded, which starts a new baseline.
__resurrect_hist_written=

# Per-prompt: flush new history lines to the (pane) HISTFILE and the archive.
# `history -a` writes only lines entered since the last append, so this never
# duplicates and never re-writes lines loaded via `history -r`.
__resurrect_hist_tmp="${TMPDIR:-/tmp}/.resurrect_hist.$$"
__resurrect_hist_sync() {
  : > "$__resurrect_hist_tmp" 2>/dev/null || return
  builtin history -a "$__resurrect_hist_tmp"
  [ -s "$__resurrect_hist_tmp" ] || return
  local chunk
  IFS= read -rd '' chunk < "$__resurrect_hist_tmp"
  __resurrect_hist_written+="$chunk"
  {
    # On lock timeout append anyway: O_APPEND never corrupts, and losing the
    # line would be worse than a rewrite racing with it.
    flock -w 2 9
    [ -n "$HISTFILE" ] && cat "$__resurrect_hist_tmp" >> "$HISTFILE"
    cat "$__resurrect_hist_tmp" >> "$__RESURRECT_HIST_ARCHIVE"
  } 9>"$__RESURRECT_HIST_LOCK"
}

# Per-prompt flushing persists each line before `history -c` / `history -d` can
# drop it, so after those options remove from disk the flushed entries that are
# no longer in the history list. Only this shell's own entries are touched; an
# entry already compacted away from the archive (keep-first by text) can't be
# retracted there.
__resurrect_hist_retract() {
  [ -n "$__resurrect_hist_written" ] || return 0
  local dir
  dir="$(mktemp -d "${TMPDIR:-/tmp}/.resurrect_hist_retract.$$.XXXXXX")" || return 1
  local subtract="$HOME/.mcnk/scripts/subtract_history.sh"
  printf '%s' "$__resurrect_hist_written" > "$dir/written"
  builtin history -w "$dir/list"
  "$subtract" "$dir/list" "$dir/written" > "$dir/removed"
  if [ ! -s "$dir/removed" ]; then
    \rm -rf "$dir"
    return 0
  fi
  local status=0 f t
  {
    if flock -w 2 9; then
      for f in "$HISTFILE" "$__RESURRECT_HIST_ARCHIVE"; do
        [ -n "$f" ] && [ -f "$f" ] || continue
        t="$(mktemp "$f.XXXXXX")" || { status=1; continue; }
        "$subtract" "$dir/removed" "$f" > "$t" && \mv -f "$t" "$f" || { \rm -f "$t"; status=1; }
      done
    else
      status=1
    fi
  } 9>"$__RESURRECT_HIST_LOCK"
  if [ "$status" -eq 0 ]; then
    __resurrect_hist_written="$("$subtract" "$dir/removed" "$dir/written"; printf x)"
    __resurrect_hist_written="${__resurrect_hist_written%x}"
  else
    echo "history: could not remove deleted entries from saved history files" >&2
  fi
  \rm -rf "$dir"
  return "$status"
}

history() {
  local arg retract=0
  for arg in "$@"; do
    case $arg in
      --) break ;;
      -*[cd]*) retract=1; break ;;
      -*) ;;
      *) break ;;
    esac
  done
  [ "$retract" -eq 1 ] || { builtin history "$@"; return; }
  # Flush first so the "lines already appended" counter equals the list length.
  # Deleting flushed entries leaves that counter too high, which would make the
  # next `history -a` skip new lines; with nothing pending, appending to
  # /dev/null resets it safely.
  __resurrect_hist_sync
  builtin history "$@" || return
  builtin history -a /dev/null
  __resurrect_hist_retract
}
case ";${PROMPT_COMMAND};" in
  *";__resurrect_hist_sync;"*) ;;
  *) PROMPT_COMMAND="__resurrect_hist_sync${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac
