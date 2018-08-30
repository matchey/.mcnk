#!/bin/bash


sshd_id=$1
if [ $# -ne 1 ]
then
	# echo "noname"
	exit
fi

FILENAME="/etc/hosts"
cat $FILENAME | while read LINE;do
	# IFS='	'
	set -- $LINE
	if [ $# -eq 2 ] && [ ${1#192.168.0.} = $sshd_id ] ; then
		echo $2
		exit
	fi
done

# echo "_"${sshd_id#192.168.0.}
# echo "noname"

