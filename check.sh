#!/bin/sh

C=100
input="/home/proxy-installer/ips.txt"

function killCmd() {
    kill $1
}

while read ip;
do
	ip_log="/tmp/check-${ip}.txt"
	nohup ping6 -c $C -I $ip google.com > $ip_log 2>&1 &
	serverPID=$!

	echo "Checking IP: $ip "

	count=0
	status=0
	until [ $status -gt 0 ]
	do
		(( count++ ))
		printf "%c""."

		if cat $ip_log | grep -q 'ttl='; then
			status=1
		fi
		if tail -n1 $ip_log | grep -q '50 packets'; then
			status=3
		fi
		if [ $count -gt 100 ]; then
			status=3
		fi
		sleep 0.5
	done

	if [ $status -eq 1 ]; then
		echo 'OK'
	else
		echo 'TIMEOUT!'
	fi

	kill $serverPID
	wait $serverPID 2>/dev/null

done < "$input"