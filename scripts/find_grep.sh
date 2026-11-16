#!/bin/bash
# usage: search <word...> [depth] [-c|-C] [ag options...]
# Searches files under the current directory up to <depth> levels (default 1).
# The pattern is a regex (ag: PCRE, grep: ERE) and is matched smart-case.
# Arguments from the first one starting with "-" (except the first word) are
# passed to ag; -c/-C among them mean "-C 3". e.g. search WORD 9 --ignore logs

usage() {
  echo "usage: $(basename "$0") <word...> [depth] [-c|-C] [ag options...]" >&2
  exit 1
}

args=()
extra_opts=()
context_opt=()
[ $# -ge 1 ] && { args=("$1"); shift; }
while [ $# -gt 0 ] && [[ $1 != -* ]]; do
  args+=("$1"); shift
done
for opt in "$@"; do
  case "$opt" in
    -c|-C) context_opt=(-C 3) ;;
    *) extra_opts+=("$opt") ;;
  esac
done
maxdepth=1
# A lone numeric argument is the search word, not the depth.
if [ ${#args[@]} -ge 2 ] && [[ ${args[-1]} =~ ^[0-9]+$ ]]; then
  maxdepth=$((10#${args[-1]}))
  unset 'args[-1]'
fi
search_word="${args[*]}"

[ -n "$search_word" ] || usage
if [ "$maxdepth" -lt 1 ]; then
  echo "depth must be 1 or greater" >&2
  usage
fi
[ ${#args[@]} -ge 2 ] && echo "\"$search_word\"" >&2

if command -v ag > /dev/null ; then
  ag --hidden --skip-vcs-ignores --ignore .git --smart-case --color --color-match '01;38;5;202' --color-path '01;38;5;132' --color-line-number 32 --depth $((maxdepth-1)) -W 500 "${context_opt[@]}" "${extra_opts[@]}" -- "$search_word"
else
  if [ ${#extra_opts[@]} -gt 0 ]; then
    echo "ag options require ag: ${extra_opts[*]}" >&2
    exit 1
  fi
  ESC=$(printf '\033')
  case_opt=-i
  [[ $search_word =~ [[:upper:]] ]] && case_opt=
  find . -maxdepth "$maxdepth" -name .git -prune -o -type f -print0 \
    | xargs -0 -r grep -s -I -H -n -E $case_opt "${context_opt[@]}" --color=always --group-separator="GREP_SEP_LINE" -e "$search_word" \
    | sed "s/GREP_SEP_LINE/\\n${ESC}[32m-=-=-=-=-=-=-=-=-=-${ESC}[m\\n/g" \
    | cut -c 1-500 | sed "s/\$/${ESC}[m/"
fi
