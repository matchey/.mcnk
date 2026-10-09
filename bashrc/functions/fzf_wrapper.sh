__fzf_hist_query_back__() {
  local saved_line=$READLINE_LINE
  local saved_point=$READLINE_POINT

  local tmp out query sel
  tmp=$(mktemp) || return 0

  out=$(
    HISTTIMEFORMAT='%Y/%m/%d %H:%M:%S ' \
    builtin history |
      sed -E 's/^[[:space:]]*[0-9]+[[:space:]]+//' |
      tac |
      awk '
        {
          line=$0
          key=line
          sub(/^[0-9]{4}\/[0-9]{2}\/[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+/, "", key)
          if (!seen[key]++) print line
        }
      ' |
      fzf --print-query --query="$saved_line" \
          --bind "ctrl-g:execute-silent(echo -n {q} > $tmp)+abort"
  )
  local ret=$?

  if [[ -s "$tmp" ]]; then
    READLINE_LINE=$(cat "$tmp")
    READLINE_POINT=${#READLINE_LINE}
    rm -f "$tmp"
    return 0
  fi
  rm -f "$tmp"

  if (( ret != 0 )); then
    READLINE_LINE=$saved_line
    READLINE_POINT=$saved_point
    return 0
  fi

  query=${out%%$'\n'*}
  sel=${out#*$'\n'}
  [[ "$sel" == "$out" ]] && sel=""

  sel=$(sed -E 's/^[0-9]{4}\/[0-9]{2}\/[0-9]{2}[[:space:]][0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+//' <<<"$sel")
  READLINE_LINE=$sel
  READLINE_POINT=${#READLINE_LINE}
}

bind -x '"\C-r": __fzf_hist_query_back__'
