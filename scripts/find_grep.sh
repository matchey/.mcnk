#!/bin/bash

search_word=$1
if [ $# -eq 0 ] ; then
	echo set searched word
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
	echo usage: search \(searched word\) \(depth\)
	exit
fi

find . -maxdepth $maxdepth -name "*" -type f | xargs fgrep -i "$search_word" --color 2>/dev/null


