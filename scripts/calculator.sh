#!/bin/bash

function Calculator() {

	read input

	if [ -z $input ] ; then

		Calculator

	# elif [ $input = 'yes' ] || [ $input = 'YES' ] || [ $input = 'y' ] ; then
    #
	# 	echo "  スクリプトを実行します."

	elif [ $input = 'quit' ] || [ $input = 'QUIT' ] || [ $input = 'q' ] ; then

		exit 1

	else
		echo "scale=5; pi=3.141592; r2d=180.0/pi; d2r=1.0/r2d; $input" | bc -l
		Calculator

	fi

}

echo "----------------------------"
echo "         calculator         "
echo "----------------------------"
echo "+ - * / % ^ ++ () pi r2d d2r"
echo "s() :sin, c() :cos, a():atan"
echo " l() :log, e() :exp, sqrt() "
echo "----------------------------"

Calculator

