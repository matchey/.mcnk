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
spawn sudo -k -p password: mount -t cifs //${IP_Garnet}/share /mnt/garnet/share -o vers=1.0
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
spawn sudo -k -p password: mount -t cifs //${IP_Garnet}/private /mnt/garnet/private -o vers=1.0
expect \"password:\" {
	send \"${SSH_PASS}\n\"
	expect \"Password for root@//${IP_Garnet}/private:\"
	send \"\n\" } \"Password for root@//${IP_Garnet}/private:\" {
	send \"\n\" }
interact
"
# ls /mnt/garnet/
cd /mnt/garnet/
ls
# exec /bin/bash
