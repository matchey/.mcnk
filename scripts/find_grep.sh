#!/bin/bash
# usage: search <word...> [depth] [-c|-C]
# Searches files under the current directory up to <depth> levels (default 1).
# The pattern is a regex (ag: PCRE, grep: ERE) and is matched smart-case.

usage() {
  echo "usage: $(basename "$0") <word...> [depth] [-c|-C]" >&2
  exit 1
}

args=("$@")
context_opt=()
case "${args[-1]-}" in
  -c|-C) context_opt=(-C 3); unset 'args[-1]' ;;
esac
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
  ag --hidden --skip-vcs-ignores --ignore .git --smart-case --color --color-match '01;38;5;202' --color-path '01;38;5;132' --color-line-number 32 --depth $((maxdepth-1)) -W 500 "${context_opt[@]}" -- "$search_word"
else
  ESC=$(printf '\033')
  case_opt=-i
  [[ $search_word =~ [[:upper:]] ]] && case_opt=
  find . -maxdepth "$maxdepth" -name .git -prune -o -type f -print0 \
    | xargs -0 -r grep -s -I -H -n -E $case_opt "${context_opt[@]}" --color=always --group-separator="GREP_SEP_LINE" -e "$search_word" \
    | sed "s/GREP_SEP_LINE/\\n${ESC}[32m-=-=-=-=-=-=-=-=-=-${ESC}[m\\n/g" \
    | cut -c 1-500 | sed "s/\$/${ESC}[m/"
fi
