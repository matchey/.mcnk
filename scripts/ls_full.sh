#!/bin/bash

list=(`ls "$@" | xargs`)

for i in ${list[@]}; do echo "`pwd`/$i"; done

