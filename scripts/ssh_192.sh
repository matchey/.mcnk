#!/bin/bash

# set Shellcmd [lindex $argv 0]

if [ $# -ne 1 ]
then
	exit
fi

Shellcmd=$1

filename="$(cd $(dirname $0) && cd .. && pwd)/.mcnk_envs"

if [ -f ${filename} ]; then
	. ${filename}
else
	echo "set SSH_PASS in ${filename}"
	exit
fi

expect -c "
set timeout 5
spawn ssh \"192.168.0.${Shellcmd}\"
expect \"connecting (yes/no)?\" {
	send \"yes\n\"
	expect \"password:\"
	send \"${SSH_PASS}\n\" } \"password:\" {
	send \"${SSH_PASS}\n\" }
interact
"

