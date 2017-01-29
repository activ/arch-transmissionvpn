#!/bin/bash

# wait for transmission process to start (listen for port)
while [[ $(netstat -lnt | awk '$6 == "LISTEN" && $4 ~ ".9091"') == "" ]]; do
	sleep 0.1
done

# define location and name of pid file
pid_file="/home/nobody/downloader.sleep.pid"

# set sleep period for recheck (in secs)
sleep_period="10"

while true; do

	# check if transmission is running, if not then kill sleep process for transmission.sh shell
	if ! pgrep -f /usr/bin/transmission-daemon > /dev/null; then

		if [[ -f "${pid_file}" ]]; then

			echo "[warn] transmission process terminated, killing sleep command in transmission.sh to force restart and refresh of ip/port..."
			pkill -P $(<"${pid_file}") sleep
			echo "[info] Sleep process killed"

			# sleep for 30 secs to give transmission chance to start before re-checking
			sleep 30s

		else

			echo "[info] No PID file containing PID for sleep command in transmission.sh present, assuming script hasn't started yet."

		fi

	fi

	sleep "${sleep_period}"s

done
