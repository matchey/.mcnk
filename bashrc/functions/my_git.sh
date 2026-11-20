# git push の -f を --force-with-lease --force-if-includes に差し替え、
# 本当に強制したい場合のみ -F (=--force) を使う運用にするラッパー。
# `--` 以降の引数は解釈対象外としてそのまま git に渡す。
# `git {diff,show,log} --inline` disables delta's side-by-side layout for that invocation.
# `git branch [--dry-run] --delete-merged <ref>` uses Git's native option (2.56+) when
# available. Older Git gets a simpler emulation: delete local branches merged into <ref>
# (a remote name means <remote>/HEAD) with `git branch -d`, keeping branches checked out
# in any worktree and the branch named like <ref> (origin/main -> main). Unlike native
# Git it ignores each branch's upstream and supports no glob or <branch-pattern>.
# --dry-run only lists the branches.

# Prints the local branch name a full ref denotes, or nothing for other refs.
_mygit_branch_name_of_ref() {
    case "$1" in
        refs/heads/*)
            printf '%s\n' "${1#refs/heads/}"
            ;;
        refs/remotes/*/*)
            local remote_ref=${1#refs/remotes/}
            printf '%s\n' "${remote_ref#*/}"
            ;;
    esac
}

# Reads `git worktree list --porcelain` and prints the checked-out branch names.
_mygit_parse_worktree_branches() {
    local line
    while IFS= read -r line; do
        if [[ "$line" == 'branch refs/heads/'* ]]; then
            printf '%s\n' "${line#branch refs/heads/}"
        fi
    done
}

# Reads branch names and prints those not given as arguments.
_mygit_select_unprotected() {
    local -A protected=()
    local name
    for name in "$@"; do
        if [[ -n "$name" ]]; then
            protected[$name]=1
        fi
    done
    while IFS= read -r name; do
        if [[ -n "$name" && -z "${protected[$name]-}" ]]; then
            printf '%s\n' "$name"
        fi
    done
}

_mygit_has_native_delete_merged() {
    local help
    help=$(command git branch -h 2>&1) || true
    [[ "$help" == *--delete-merged* ]]
}

_mygit_merged_local_branches() {
    local ref=$1 remotes full_ref merged worktrees
    remotes=$(command git remote) || return
    if [[ $'\n'"$remotes"$'\n' == *$'\n'"$ref"$'\n'* ]]; then
        if ! ref=$(command git rev-parse --verify --quiet --abbrev-ref "$ref/HEAD"); then
            printf "mygit: %s/HEAD is not set; run 'git remote set-head %s --auto'\n" \
                "$1" "$1" >&2
            return 1
        fi
    fi
    full_ref=$(command git rev-parse --verify --quiet --symbolic-full-name "$ref") || full_ref=''
    merged=$(command git for-each-ref --merged="$ref" \
        --format='%(refname:lstrip=2)' refs/heads/) || return
    worktrees=$(command git worktree list --porcelain) || return
    local protected=()
    mapfile -t protected < <(_mygit_parse_worktree_branches <<<"$worktrees")
    _mygit_select_unprotected "$(_mygit_branch_name_of_ref "$full_ref")" "${protected[@]}" \
        <<<"$merged"
}

_mygit_branch_delete_merged() {
    if _mygit_has_native_delete_merged; then
        command git branch "$@"
        return
    fi
    local dry_run=0 unsupported=0 refs=() arg
    for arg in "$@"; do
        case "$arg" in
            --dry-run) dry_run=1 ;;
            --delete-merged) ;;
            --delete-merged=*) refs+=("${arg#--delete-merged=}") ;;
            -*) unsupported=1 ;;
            *) refs+=("$arg") ;;
        esac
    done
    if (( unsupported || ${#refs[@]} != 1 )) || [[ "${refs[0]}" == *[\*\?\[]* ]]; then
        printf 'mygit: this Git supports only: git branch [--dry-run] --delete-merged <remote|ref>\n' >&2
        return 2
    fi
    local names
    names=$(_mygit_merged_local_branches "${refs[0]}") || return
    if [[ -z "$names" ]]; then
        return 0
    fi
    if (( dry_run )); then
        printf '%s\n' "$names"
        return 0
    fi
    local branches=()
    mapfile -t branches <<<"$names"
    command git branch -d -- "${branches[@]}"
}

mygit() {
    if [[ "$1" == branch ]]; then
        local branch_arg
        for branch_arg in "${@:2}"; do
            if [[ "$branch_arg" == --delete-merged || "$branch_arg" == --delete-merged=* ]]; then
                shift
                _mygit_branch_delete_merged "$@"
                return
            fi
        done
    fi
    if [[ "$1" == "diff" || "$1" == "show" || "$1" == "log" ]]; then
        local subcommand=$1
        shift
        local args=()
        local diff_config=()
        local passthrough=0
        local arg
        for arg in "$@"; do
            if (( passthrough )); then
                args+=("$arg")
                continue
            fi
            case "$arg" in
                --)
                    passthrough=1
                    args+=("$arg")
                    ;;
                --inline)
                    diff_config=(-c delta.side-by-side=false)
                    ;;
                *)
                    args+=("$arg")
                    ;;
            esac
        done
        command git "${diff_config[@]}" "$subcommand" "${args[@]}"
        return
    fi
    if [[ "$1" != "push" ]]; then
        command git "$@"
        return
    fi
    shift

    local args=()
    local force_mode=()
    local passthrough=0
    for arg in "$@"; do
        if (( passthrough )); then
            args+=("$arg")
            continue
        fi
        case "$arg" in
            --)
                passthrough=1
                args+=("$arg")
                ;;
            -f)
                force_mode=(--force-with-lease --force-if-includes)
                ;;
            -F)
                force_mode=(--force)
                ;;
            *)
                args+=("$arg")
                ;;
        esac
    done
    command git push "${force_mode[@]}" "${args[@]}"
}

# alias git=mygit
