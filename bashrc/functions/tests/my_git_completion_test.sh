#!/usr/bin/env bash
set -e

source /usr/share/bash-completion/completions/git
source "$(dirname "${BASH_SOURCE[0]}")/../../bash_completion"

assert_completion() {
    local expected=$1
    local candidate=$2
    shift 2
    COMP_WORDS=("$@")
    COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
    COMP_LINE="${COMP_WORDS[*]}"
    COMP_POINT=${#COMP_LINE}
    COMPREPLY=()
    local spec function_name found=0 reply
    spec=$(complete -p "${COMP_WORDS[0]}")
    function_name=${spec#* -F }
    function_name=${function_name%% *}
    "$function_name"
    for reply in "${COMPREPLY[@]}"; do
        if [[ "${reply% }" == "$candidate" ]]; then
            found=1
        fi
    done
    if [[ "$found" != "$expected" ]]; then
        printf 'Unexpected completion for %s: %s\n' "$COMP_LINE" "${COMPREPLY[*]}" >&2
        exit 1
    fi
}

assert_completion 1 --inline git diff --inl
assert_completion 1 --inline mygit diff --inl
assert_completion 1 --inline git diff --cached --inl
assert_completion 1 --cached git diff --ca
assert_completion 1 --short git status --sh
for subcommand in show log; do
    assert_completion 1 --inline git "$subcommand" --inl
    assert_completion 1 --inline mygit "$subcommand" --inl
    assert_completion 1 --inline git "$subcommand" -p --inl
    assert_completion 1 --stat git "$subcommand" --sta
    assert_completion 0 --inline git "$subcommand" -- --inl
done
assert_completion 1 oneline git show --format=onel
assert_completion 1 short git log --date=sh
assert_completion 0 --inline git difftool --inl
assert_completion 0 --inline git diff -- --inl

source "$(dirname "${BASH_SOURCE[0]}")/../../bash_completion"
assert_completion 1 --inline git diff --inl
assert_completion 1 --inline git show --inl
assert_completion 1 --inline git log --inl
printf 'mygit completion tests passed\n'
