#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_eq() {
    local name=$1 expected=$2 actual=$3
    if [[ "$actual" != "$expected" ]]; then
        printf 'FAIL: %s\nExpected:\n%s\nActual:\n%s\n' "$name" "$expected" "$actual" >&2
        exit 1
    fi
}

# --- subtract_history.sh (pure filter) --------------------------------------

printf '#1\necho a\n#2\necho b\n' > "$work/remove"
printf 'untimed\n#1\necho a\n#2\necho b\nline2\n#1\necho a\n#3\necho c\n' > "$work/target"
assert_eq "subtract drops only the latest matching occurrence (ts+command)" \
    $'untimed\n#1\necho a\n#2\necho b\nline2\n#3\necho c' \
    "$("$repo/scripts/subtract_history.sh" "$work/remove" "$work/target")"

printf '#2\necho b\nline2\n' > "$work/remove"
assert_eq "subtract matches multi-line entries as a whole" \
    $'untimed\n#1\necho a\n#1\necho a\n#3\necho c' \
    "$("$repo/scripts/subtract_history.sh" "$work/remove" "$work/target")"

: > "$work/remove"
assert_eq "subtract with nothing to remove is identity" \
    "$(cat "$work/target")" \
    "$("$repo/scripts/subtract_history.sh" "$work/remove" "$work/target")"

# --- interactive shell: history -c / -d retract this session's flushed lines --

command -v script >/dev/null || fail "script(1) is required"

home="$work/home"
mkdir -p "$home"
ln -s "$repo" "$home/.mcnk"
cat > "$work/rc" <<EOF
HISTCONTROL=ignoreboth
HISTTIMEFORMAT='%F '
HISTFILE=\$HOME/.bash_history
trap '. "$repo/scripts/save_history_uniq.sh"' EXIT
source "$repo/bashrc/functions/resurrect_pane_hist.sh"
EOF

# Feed commands line by line to a real interactive bash so PROMPT_COMMAND runs.
run_shell() {
    env -u TMUX HOME="$home" TMPDIR="$work" \
        script -qec "bash --rcfile '$work/rc' -i" /dev/null <<<"$1" >/dev/null
}

commands_in() {
    grep -v '^#[0-9]*$' "$1" || true
}

reset_files() {
    printf '#1000000000\necho other-session\n#1000000001\necho SECRET\n' > "$home/.bash_history_uniq"
    : > "$home/.bash_history"
}

reset_files
run_shell $'echo before\necho SECRET\nhistory -c\necho after\nexit'
assert_eq "history -c: HISTFILE keeps only lines after the clear" \
    $'echo after\nexit' "$(commands_in "$home/.bash_history")"
assert_eq "history -c: archive keeps other sessions' entries" \
    $'echo other-session\necho SECRET\necho after\nexit' \
    "$(commands_in "$home/.bash_history_uniq")"

reset_files
run_shell $'echo d1\necho SECRET\nhistory -d 2\necho d2\nexit'
assert_eq "history -d: only the deleted entry is removed from HISTFILE" \
    $'echo d1\nhistory -d 2\necho d2\nexit' "$(commands_in "$home/.bash_history")"
assert_eq "history -d: only the deleted entry is removed from the archive" \
    $'echo other-session\necho SECRET\necho d1\nhistory -d 2\necho d2\nexit' \
    "$(commands_in "$home/.bash_history_uniq")"

reset_files
run_shell $'echo e1\necho e2\nhistory -d 1\nhistory -d 1\necho f1\necho f2\nexit'
assert_eq "history -d: lines entered after deletions are all still saved" \
    $'history -d 1\necho f1\necho f2\nexit' "$(commands_in "$home/.bash_history")"

reset_files
run_shell $'echo n1\necho n2\nhistory 1 >/dev/null\nexit'
assert_eq "plain history use keeps every flushed line" \
    $'echo n1\necho n2\nhistory 1 >/dev/null\nexit' "$(commands_in "$home/.bash_history")"

echo "resurrect_pane_hist tests passed"
