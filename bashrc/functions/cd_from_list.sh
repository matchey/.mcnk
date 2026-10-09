
function list_cd()
{
  if [ $# -eq 0 ];then
    OLD_IFS="$IFS"
    IFS=':'
    local selected
    selected=$(
      for i in $h;do
        echo "$i"
      done | fzf --height=40% --reverse
    )
    IFS="$OLD_IFS"
    if [ -n "$selected" ]; then
      cd "$selected"
    fi
  else
    if [[ "$1" =~ ^[0-9]+$ ]]; then
      list=$h
      cd "$(echo $list | cut -f $1 -d ":")"
    fi
  fi
}

