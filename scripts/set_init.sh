#!/bin/bash


args="$@"
list=(${args//,/ })

if [ ${#list[@]} -ne 4 ] ; then
  exit
fi

filename=${list[0]}
x=${list[1]}
y=${list[2]}
yaw=`echo "scale=4; ${list[3]}*3.14159265/180.0" | bc`

echo --
echo $filename
echo --
cat $filename
echo --

sed -i -e "s/x: [+-]\?[0-9]*.[0-9]*/x: $x/" $filename
sed -i -e "s/y: [+-]\?[0-9]*.[0-9]*/y: $y/" $filename
sed -i -e "s/yaw: [+-]\?[0-9]*.[0-9]*/yaw: $yaw/" $filename

cat $filename

