#!/bin/bash

search_word=$1
context=""
if [ $# -eq 0 ] ; then
	echo set searched word
	echo usage: search \(searched word\) \(depth\)
	exit
elif [ $# -eq 1 ] ; then
	maxdepth=1
elif [ $# -eq 2 ] ; then
	if expr "$2" : '[0-9]*' > /dev/null ; then
    maxdepth=$2
	else
		maxdepth=1
		search_word="$1 $2"
		echo \"$search_word\"
	fi
else
  last="${@:$#:1}"
	if expr "${*:$#}" : '[0-9]*' > /dev/null ; then
    maxdepth=${*:$#}
		search_word="${*:1:$#-1}"
  elif [ $last == '-c' ] || [ $last == '-C' ]; then
		maxdepth="${*:2:$#-2}"
		search_word="${*:1:$#-2}"
    context=-3
	else
		maxdepth=1
		search_word="$*"
		echo \"$search_word\"
	fi
fi

if [ -z "$search_word" ]; then
	echo set searched word
	echo usage: search \(searched word\) \(depth\)
	exit
fi

ESC=$(printf '\033')
# find . -maxdepth $maxdepth -name "*" -type f | xargs fgrep -I -i "$search_word" --color 2>/dev/null
find . -maxdepth $maxdepth -name "*" -type f 2>/dev/null | xargs grep $context -I -i "${search_word}" -n --color=always --group-separator="GREP_SEP_LINE"  2>/dev/null | sed "s/GREP_SEP_LINE/\n${ESC}[32m-=-=-=-=-=-=-=-=-=-${ESC}[m\n/g" | grep -i -E "|.{,50}${search_word}.{,50}" | cut -c 1-500 2>/dev/null

