#!/bin/bash

mkdir "$(cd $(dirname $0) && pwd)/cmd"

cd $(cd $(dirname $0) && pwd)

git update-index --skip-worktree .mcnk_envs

cd cmd

ln -s ../scripts/calculator.sh calc

ln -s ../scripts/getOnIP.sh connection

ln -s ../scripts/ctrl_nocaps.sh ctrl_nocaps

ln -s ../scripts/mnt_garnet.sh garnet

ln -s ../scripts/host2ip.sh host2ip

ln -s ../scripts/ip2host.sh ip2host

ln -s ../scripts/interrupt_pts.sh kt

ln -s ../scripts/ls_full.sh lf

ln -s ../scripts/find_grep.sh search

ln -s ../scripts/scp_192.sh sscp

ln -s ../scripts/ssh_192.sh sshh

ln -s ../scripts/umnt_garnet.sh umnt_g

echo "export PATH=$(pwd):"'${PATH}' >> ~/.bashrc

