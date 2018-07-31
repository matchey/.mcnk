#!/bin/bash

if [ $# -ne 1 ]
then
	# echo "noname"
	exit
fi

word=$1

filename="$(cd $(dirname $0) && cd .. && pwd)/db/gene-utf8.txt"

grep $1 ${filename} -E -A 1 -wi --color

