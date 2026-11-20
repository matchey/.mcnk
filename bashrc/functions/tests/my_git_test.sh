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
for subcommand in show log; do
    assert_args "<git><$subcommand><HEAD>" "$subcommand" HEAD
    assert_args "<git><-c><delta.side-by-side=false><$subcommand><HEAD>" \
        "$subcommand" --inline HEAD
    assert_args "<git><-c><delta.side-by-side=false><$subcommand><-p><-3><--><a b.txt>" \
        "$subcommand" -p --inline -3 -- 'a b.txt'
    assert_args "<git><$subcommand><--><--inline>" "$subcommand" -- --inline
    assert_args "<git><-c><delta.side-by-side=false><$subcommand><HEAD>" \
        "$subcommand" --inline HEAD --inline
done
assert_args '<git><push><--force-with-lease><--force-if-includes><origin><main>' \
    push -f origin main
assert_args '<git><push><--force><origin><main>' push -F origin main
assert_args '<git><push><--force><origin>' push -f -F origin
assert_args '<git><push><--><-f>' push -- -f

git_status=23
for subcommand in diff show log; do
    if mygit "$subcommand" --inline >/dev/null; then
        printf 'Expected Git exit status to propagate\n' >&2
        exit 1
    else
        status=$?
        [[ "$status" == 23 ]]
    fi
done
git_status=0

assert_equal() {
    if [[ "$2" != "$1" ]]; then
        printf 'Expected: %s\nActual:   %s\n' "$1" "$2" >&2
        exit 1
    fi
}

assert_equal main "$(_mygit_branch_name_of_ref refs/remotes/origin/main)"
assert_equal feature/x "$(_mygit_branch_name_of_ref refs/heads/feature/x)"
assert_equal '' "$(_mygit_branch_name_of_ref refs/tags/v1)"
assert_equal '' "$(_mygit_branch_name_of_ref '')"

# Fake Git repository state for `branch --delete-merged`.
branch_help='--merged <commit>'
merged_branches=$'current\nfeature-a\nfeature/c\nmain\nwt-branch'
origin_head=origin/main
delete_status=0
command() {
    case "$*" in
        'git branch -h')
            printf '%s\n' "$branch_help"
            return 129
            ;;
        'git remote')
            printf 'origin\nupstream\n'
            ;;
        'git rev-parse --verify --quiet --abbrev-ref origin/HEAD')
            [[ -n "$origin_head" ]] || return 1
            printf '%s\n' "$origin_head"
            ;;
        'git rev-parse --verify --quiet --symbolic-full-name origin/main')
            printf 'refs/remotes/origin/main\n'
            ;;
        'git rev-parse --verify --quiet --symbolic-full-name main')
            printf 'refs/heads/main\n'
            ;;
        'git for-each-ref --merged='*' --format=%(refname:lstrip=2) refs/heads/')
            [[ -n "$merged_branches" ]] && printf '%s\n' "$merged_branches"
            return 0
            ;;
        'git worktree list --porcelain')
            printf 'worktree /repo\nHEAD 1\nbranch refs/heads/current\n\n'
            printf 'worktree /repo-wt\nHEAD 2\nbranch refs/heads/wt-branch\n\n'
            printf 'worktree /repo-detached\nHEAD 3\ndetached\n'
            ;;
        *)
            printf '<%s>' "$@"
            [[ "$2" == branch && "$3" == -d ]] && return "$delete_status"
            return 0
            ;;
    esac
}

assert_args '<git><branch><-a>' branch -a
assert_args $'feature-a\nfeature/c' branch --dry-run --delete-merged origin
assert_args $'feature-a\nfeature/c' branch --delete-merged origin --dry-run
assert_args '<git><branch><-d><--><feature-a><feature/c>' branch --delete-merged origin
assert_args '<git><branch><-d><--><feature-a><feature/c>' branch --delete-merged origin/main
assert_args '<git><branch><-d><--><feature-a><feature/c>' branch --delete-merged main
assert_args '<git><branch><-d><--><feature-a><feature/c>' branch --delete-merged=origin

delete_status=1
if mygit branch --delete-merged origin >/dev/null; then
    printf 'Expected branch -d exit status to propagate\n' >&2
    exit 1
fi
delete_status=0

assert_unsupported() {
    local status=0
    mygit branch "$@" >/dev/null 2>&1 || status=$?
    assert_equal 2 "$status"
}
assert_unsupported --delete-merged
assert_unsupported --delete-merged 'origin/*'
assert_unsupported --delete-merged origin 'feature-*'
assert_unsupported --delete-merged origin -v

origin_head=''
status=0
mygit branch --delete-merged origin >/dev/null 2>&1 || status=$?
assert_equal 1 "$status"
origin_head=origin/main

merged_branches=$'current\nmain'
assert_args '' branch --delete-merged origin
assert_args '' branch --dry-run --delete-merged origin

branch_help='--delete-merged <pattern>'
assert_args "<git><branch><--dry-run><--delete-merged><origin/*><feature-*>" \
    branch --dry-run --delete-merged 'origin/*' 'feature-*'

printf 'mygit tests passed\n'
