#!/bin/bash

ips=(`echo 172.16.76.{1..254} | xargs -P256 -n1 ping -s1 -c1 -W1 | grep ttl`)

# ips=($(for v in "${ipss[@]%.*}"; do echo "$v"; done | sort -n))
# echo ${ips[@]}

array=()
for i in ${ips[@]}; do
	if [ ${i%.*} = "172.16.76" ] ; then
		ip=${i%:}
		array+=(${ip#172.16.76.})
	fi
done

array=(`for i in "${array[@]}"; do echo "$i"; done | sort -n`)
for i in ${array[@]}; do
	hostname=`echo $i | xargs ip2host`
	if [ -n "$hostname" ]; then
		echo "172.16.76.$i ($hostname)"
	else
		echo 172.16.76.$i
	fi
done

