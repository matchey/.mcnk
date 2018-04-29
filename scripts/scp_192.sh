#!/bin/bash

#!/usr/bin/expect

# set file [lindex $argv 0]
# set ip [lindex $argv 1]

if [ $# -ne 2 ]
then
	exit
fi

file=$1
ip=$2

filename="$(cd $(dirname $0) && cd .. && pwd)/.mcnk_envs"

if [ -f ${filename} ]; then
	. ${filename}
else
	echo "set SSH_PASS in ${filename}"
	exit
fi

expect -c "
set timeout 5
spawn scp \"-r\" \"${file}\" \"192.168.0.${ip}:\"
expect \"connecting (yes/no)?\" {
	send \"yes\n\"
	expect \"password:\"
	send \"${SSH_PASS}\n\" } \"password:\" {
	send \"${SSH_PASS}\n\" }
interact
"

