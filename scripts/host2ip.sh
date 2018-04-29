#!/bin/bash


hostname=$1
if [ $# -ne 1 ]
then
	# echo "noname"
	exit
fi

FILENAME="/etc/hosts"
cat $FILENAME | while read LINE;do
	IFS='	'
	set -- $LINE
	if [ $# -eq 2 ] && [ $2 = $hostname ] ; then
		echo ${1#192.168.0.}
		exit
	fi
done

# echo "_"${hostname#192.168.0.}
# echo "noname"

