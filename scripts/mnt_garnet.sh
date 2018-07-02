#!/bin/bash

#sudo apt-get install expect
#sudo apt-get install cifs-utils
#sudo mkdir -p /mnt/garnet/private /mnt/garnet/share

filename="$(cd $(dirname $0) && cd .. && pwd)/.mcnk_envs"

if [ -f ${filename} ]; then
	. ${filename}
else
	echo "set SSH_PASS in ${filename}"
	exit
fi

expect -c "
set timeout 5
spawn sudo -k -p password: mount -t cifs -o vers=1.0,uid=$(id -u),gid=$(id -g),dir_mode=0775,file_mode=0664 //${IP_Garnet}/share /mnt/garnet/share
expect \"password:\" {
	send \"${SSH_PASS}\n\"
	expect \"Password for root@//${IP_Garnet}/share:\"
	send \"\n\" } \"Password for root@//${IP_Garnet}/share:\" {
	send \"\n\" }
interact
"

sleep 0.5s

expect -c "
set timeout 5
spawn sudo -k -p password: mount -t cifs -o vers=1.0,uid=$(id -u),gid=$(id -g),dir_mode=0775,file_mode=0664 //${IP_Garnet}/private /mnt/garnet/private
expect \"password:\" {
	send \"${SSH_PASS}\n\"
	expect \"Password for root@//${IP_Garnet}/private:\"
	send \"\n\" } \"Password for root@//${IP_Garnet}/private:\" {
	send \"\n\" }
interact
"
# ls /mnt/garnet/
cd /mnt/garnet/
ls --color=auto
exec /bin/bash # ". garnet" is better??

#dynperm, noperm らへんのoptionがよくわからん...

