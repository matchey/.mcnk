#!/bin/bash

if [ $# -eq 0 ] ; then
	exit
fi

find_dir="${PWD}"
search_word=$1

for i in {0..100};do
  if [ $find_dir == "/" ]; then
    break
  fi
  fname=`find "${find_dir}" -maxdepth 1 -name "$search_word"`
  if [ -e "$fname" ]; then
    echo $fname # do something here
    break
  fi
  find_dir=$(builtin cd $find_dir/../ && pwd)
done

