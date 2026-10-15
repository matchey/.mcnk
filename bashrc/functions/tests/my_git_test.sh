#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../my_git.sh"

# Capture the external Git boundary without executing repository operations.
command() {
    printf '<%s>' "$@"
    return "${git_status:-0}"
}

assert_args() {
    local expected=$1
    shift
    local actual
    actual=$(mygit "$@")
    if [[ "$actual" != "$expected" ]]; then
        printf 'Expected: %s\nActual:   %s\n' "$expected" "$actual" >&2
        exit 1
    fi
}

assert_args '<git><status><--short>' status --short
assert_args '<git><diff><--stat>' diff --stat
assert_args '<git><-c><delta.side-by-side=false><diff>' diff --inline
assert_args '<git><-c><delta.side-by-side=false><diff><--cached><--><a b.txt>' \
    diff --cached --inline -- 'a b.txt'
assert_args '<git><-c><delta.side-by-side=false><diff><HEAD~1><HEAD>' \
    diff --inline HEAD~1 --inline HEAD
assert_args '<git><diff><--unified=5>' diff --unified=5
assert_args '<git><diff><--unified>' diff --unified
assert_args '<git><diff><--><--inline>' diff -- --inline
assert_args '<git><-c><delta.side-by-side=false><diff><--><--inline>' \
    diff --inline -- --inline
assert_args '<git><push><--force-with-lease><--force-if-includes><origin><main>' \
    push -f origin main
assert_args '<git><push><--force><origin><main>' push -F origin main
assert_args '<git><push><--force><origin>' push -f -F origin
assert_args '<git><push><--><-f>' push -- -f

git_status=23
if mygit diff --inline >/dev/null; then
    printf 'Expected Git exit status to propagate\n' >&2
    exit 1
else
    status=$?
    [[ "$status" == 23 ]]
fi

printf 'mygit tests passed\n'
