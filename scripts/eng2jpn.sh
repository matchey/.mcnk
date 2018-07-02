#!/bin/bash

if [ $# -ne 1 ]
then
	# echo "noname"
	exit
fi

word=$1

grep $1 ~/Downloads/gene-utf8.txt -E -A 1 -wi --color

