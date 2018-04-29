#!/bin/bash

#sudo apt-get install cifs-utils

filename="$(cd $(dirname $0) && cd .. && pwd)/.mcnk_envs"

if [ -f ${filename} ]; then
	. ${filename}
else
	echo "set SSH_PASS in ${filename}"
	exit
fi

cd /mnt/garnet

expect -c "
set timeout 5

spawn sudo -k -p password: umount /mnt/garnet/share
expect \"password:\" {
	send \"${SSH_PASS}\n\" 
}
interact
"

# xte "usleep 150"
sleep 0.5s

expect -c "
set timeout 5
spawn sudo -k -p password: umount /mnt/garnet/private
expect \"password:\" {
	send \"${SSH_PASS}\n\" }
interact
"
# spawn ls
# expect \"$\"
# send \"exit\n\"
# "
# # if [ "$SHLVL" = 1 ]; then
#     [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
# # fi
sleep 0.5s
ls --color=auto

