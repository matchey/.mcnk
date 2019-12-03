#!/bin/bash

if [ $# -ne 1 ]
then
	# echo "noname"
	exit
fi

word=$1

filename="$(cd $(dirname $0) && cd .. && pwd)/db/gene-utf8.txt"

result=`grep $1 ${filename} -E -A 1 -wi --color=always`

if [ -z "${result}" ]; then
  grep $1 ${filename} -E -A 1 -i --color
else
  echo "${result}"
  # grep $1 ${filename} -E -A 1 -wi --color
fi

