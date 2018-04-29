#!/bin/bash

bagfile=$1

if [ $# -ne 1 ]
then
	exit
fi

IFS='.'
set -- $bagfile

rosbag filter $1.bag ${1}_filtered.bag "topic=='/AMU_data' or topic=='/velodyne_packets' or topic=='/tinypower/odom'"

