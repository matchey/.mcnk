# git push の -f を --force-with-lease --force-if-includes に差し替え、
# 本当に強制したい場合のみ -F (=--force) を使う運用にするラッパー。
# `--` 以降の引数は解釈対象外としてそのまま git に渡す。
# `git diff --inline` disables delta's side-by-side layout for that invocation.
mygit() {
    if [[ "$1" == "diff" ]]; then
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
        command git "${diff_config[@]}" diff "${args[@]}"
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
