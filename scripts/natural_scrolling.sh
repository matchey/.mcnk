#!/bin/bash

mouse_name="Master 2S"

id=`xinput list | grep "${mouse_name}" | grep -o id=[0-9]*`
id=${id#id=}

if [[ "${id}" =~ ^[0-9]+$ ]]; then
	num=`xinput list-props ${id} | grep -o "Scrolling Distance ([0-9]*"`
	num=${num#Scrolling Distance (}
	if [[ "${num}" =~ ^[0-9]+$ ]]; then
		xinput set-prop $id $num -1 -1 -1
	fi
else
	echo "set your mouse name in"
	echo $(cd $(dirname $0); pwd)"/"$(basename $0)
	exit
fi


