#!/bin/bash

mcnkdir=$(cd $(dirname $0) && pwd)

cd ${mcnkdir}

git update-index --skip-worktree .mcnk_envs

if [ ! -d "${mcnkdir}/cmd" ]; then
  mkdir "${mcnkdir}/cmd"
fi

cd cmd

ln -s ../scripts/calculator.sh calc

ln -s ../scripts/getOnIP.sh connection

ln -s ../scripts/ctrl_nocaps.sh ctrl_nocaps

ln -s ../scripts/eng2jpn.sh dict

# ln -s ../scripts/mnt_garnet.sh garnet

ln -s ../scripts/host2ip.sh host2ip

ln -s ../scripts/ip2host.sh ip2host

ln -s ../scripts/interrupt_pts.sh kt

ln -s ../scripts/ls_full.sh lf

ln -s ../scripts/showMyIP.sh mip

ln -s ../scripts/find_grep.sh search

ln -s ../scripts/idle_handle_mouse.sh expand_mouse

# ln -s ../scripts/scp_192.sh sscp

# ln -s ../scripts/ssh_192.sh sshh

# ln -s ../scripts/umnt_garnet.sh umnt_g

# echo "export PATH=$(pwd):"'${PATH}' >> ~/.bashrc
# echo ". ~/.mcnk/bashrc/bash_aliases" >> ~/.bash_aliases
# echo <<EOS >> ~/.bashrc

if [ ! -f ${HOME}/.lastpwd ]; then
  touch ${HOME}/.lastpwd
fi

mcnkdir_v='${MCNK_ROOT_DIR}'
cat << EOS >> ~/.bashrc

# mcnk
export MCNK_ROOT_DIR="${mcnkdir}"
if [ -f ${mcnkdir_v}/bashrc/bashrc ]; then
    . ${mcnkdir_v}/bashrc/bashrc
fi
EOS

