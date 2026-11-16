#!/bin/bash
# usage: fname <name> [f|d] [depth]
# Lists files and directories under the current directory whose name contains
# <name> (glob, smart-case). f/d restricts the type; depth defaults to unlimited.
# Hidden and VCS-ignored entries are included, except .git, as in ftext.

usage() {
  echo "usage: $(basename "$0") <name> [f|d] [depth]" >&2
  exit 1
}

[ $# -ge 1 ] && [ -n "$1" ] || usage
name=$1; shift
type=
maxdepth=
for arg in "$@"; do
  case "$arg" in
    f|d) type=$arg ;;
    *)
      [[ $arg =~ ^[0-9]+$ ]] || usage
      maxdepth=$((10#$arg))
      if [ "$maxdepth" -lt 1 ]; then
        echo "depth must be 1 or greater" >&2
        usage
      fi
      ;;
  esac
done

# Ubuntu's fd-find package installs the binary as fdfind.
fd_bin=$(command -v fd || command -v fdfind)
if [ -n "$fd_bin" ]; then
  "$fd_bin" --hidden --no-ignore --exclude .git --glob \
    ${type:+--type "$type"} ${maxdepth:+--max-depth "$maxdepth"} -- "*${name}*"
else
  name_opt=-iname
  [[ $name =~ [[:upper:]] ]] && name_opt=-name
  find . ${maxdepth:+-maxdepth "$maxdepth"} -name .git -prune -o \
    $name_opt "*${name}*" ${type:+-type "$type"} -print 2>/dev/null
fi
