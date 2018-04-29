#!/bin/bash

__read_pts() {
	# local line pidlists=""
	
	ps -A | while read line; do
		IFS=' '
		set -- $line
		if [[ $2 = pts* ]] ; then
		# if [ `echo '$3' | grep 'pts'` ] ; then
				# pidlists+="$0 "
				# echo "$line"
				# echo "$1"
				if [[ $4 != ps ]] ;then
				if [[ $4 != vim ]] ;then
						kill -s 2 $1
				fi
				fi
		fi
	done
	# echo $pidlists
	return 0
}

main() {
	local pidlists=""

	pidlists=`ps -A | __read_pts`

	echo $pidlists

	return 0
}

# main $@

__read_pts $@

# _known_hosts $@

