#!/bin/bash

# if vpn set to "no" then don't run openvpn
if [[ "${VPN_ENABLED}" == "no" ]]; then

	echo "[info] VPN not enabled, skipping VPN tunnel local ip/port checks"

	transmission_ip="0.0.0.0"

	echo "[info] Removing any transmission session lock files left over from the previous run..."
	rm -f /config/transmission/session/*.lock

	# run transmission
	echo "[info] Attempting to start transmission..."
	/usr/bin/script /home/nobody/typescript --command "/usr/bin/tmux new-session -s rt -n transmission /usr/bin/transmission-daemon "--foreground" "--config-dir" "/config" "--allowed" "${WHITELIST}" " &>/dev/null

else

	echo "[info] VPN is enabled, checking VPN tunnel local ip is valid"

	# create pia client id (randomly generated)
	client_id=`head -n 100 /dev/urandom | md5sum | tr -d " -"`


	# run script to check ip is valid for tunnel device
	source /home/nobody/checkvpnip.sh

	# set triggers to first run
	transmission_running="false"
	ip_change="false"
	port_change="false"

	# set default values for port and ip
	transmission_port=""
	transmission_ip="0.0.0.0"

	# remove previously run pid file (if it exists)
	rm -f /home/nobody/downloader.sleep.pid
	
	# while loop to check ip and port
	while true; do

		# write the current session's pid to file (used to kill sleep process if transmission/openvpn terminates)
		echo $$ > /home/nobody/downloader.sleep.pid

		# run script to check ip is valid for tunnel device (will block until valid)
		source /home/nobody/checkvpnip.sh

		# run scripts to identity vpn ip
		source /home/nobody/getvpnip.sh

		# if vpn_ip is not blank then run, otherwise log warning
		if [[ ! -z "${vpn_ip}" ]]; then

			# check if transmission is running, if not then skip reconfigure for port/ip
			if ! pgrep -f /usr/bin/transmission-daemon > /dev/null; then

				echo "[info] transmission not running"

				# mark as transmission not running
				transmission_running="false"

			else

				# if transmission is running, then reconfigure port/ip
				transmission_running="true"

			fi

			# if current bind interface ip is different to tunnel local ip then re-configure transmission
			if [[ "${transmission_ip}" != "${vpn_ip}" ]]; then

				echo "[info] transmission listening interface IP $transmission_ip and VPN provider IP ${vpn_ip} different, marking for reconfigure"

				# mark as reload required due to mismatch
				ip_change="true"

			fi

			if [[ "${VPN_PROV}" == "pia" ]]; then

				# run scripts to identify vpn port
				source /home/nobody/getvpnport.sh

				# if vpn port is not an integer then log warning
				if [[ ! "${VPN_INCOMING_PORT}" =~ ^-?[0-9]+$ ]]; then

					echo "[warn] PIA incoming port is not an integer, downloads will be slow, does PIA remote gateway supports port forwarding?"

					# set vpn port to current transmission port, as we currently cannot detect incoming port (line saturated, or issues with pia)
					VPN_INCOMING_PORT="${transmission_port}"

				else

					if [[ "${transmission_running}" == "true" ]]; then

						# run netcat to identify if port still open, use exit code
						nc_exitcode=$(/usr/bin/nc -z -w 3 "${transmission_ip}" "${transmission_port}")

						if [[ "${nc_exitcode}" -ne 0 ]]; then

							echo "[info] transmission incoming port closed, marking for reconfigure"

							# mark as reconfigure required due to mismatch
							port_change="true"

						elif [[ "${transmission_port}" != "${VPN_INCOMING_PORT}" ]]; then

							echo "[info] transmission incoming port $transmission_port and VPN incoming port ${VPN_INCOMING_PORT} different, marking for reconfigure"

							# mark as reconfigure required due to mismatch
							port_change="true"

						fi

					fi

				fi

			fi

			if [[ "${transmission_running}" == "true" ]]; then

				if [[ "${VPN_PROV}" == "pia" ]]; then

					# reconfigure transmission with new port
					if [[ "${port_change}" == "true" ]]; then

						echo "[info] Reconfiguring transmission due to port change..."
						/usr/bin/script /home/nobody/typescript --command "killall transmission-daemon"
						/usr/bin/script /home/nobody/typescript --command "/usr/bin/tmux new-session -d -s rt -n transmission /usr/bin/transmission-daemon "--foreground" "--config-dir" "/config" "--allowed" "${WHITELIST}" "--bind-address-ipv4" "${transmission_ip}" "--peerport" "$transmission_port""
						echo "[info] transmission reconfigured for port change"

					fi
				fi

				# reconfigure transmission with new ip
				if [[ "${ip_change}" == "true" ]]; then

					echo "[info] Reconfiguring transmission due to ip change..."
					/usr/bin/script /home/nobody/typescript --command "killall transmission-daemon"
					/usr/bin/script /home/nobody/typescript --command "/usr/bin/tmux new-session -d -s rt -n transmission /usr/bin/transmission-daemon "--foreground" "--config-dir" "/config" "--allowed" "${WHITELIST}" "--bind-address-ipv4" "${transmission_ip}" "--peerport" "$transmission_port""
					echo "[info] transmission reconfigured for ip change"

				fi

			else

				echo "[info] Attempting to start transmission..."

				echo "[info] Removing any transmission session lock files left over from the previous run..."
				rm -f /config/transmission/session/*.lock

				if [[ "${VPN_PROV}" == "pia" || -n "${VPN_INCOMING_PORT}" ]]; then

					# run tmux attached to transmission, specifying listening interface and port
					/usr/bin/script /home/nobody/typescript --command "/usr/bin/tmux new-session -d -s rt -n transmission /usr/bin/transmission-daemon "--foreground" "--config-dir" "/config" "--allowed" "${WHITELIST}" "--bind-address-ipv4" "${transmission_ip}" "--peerport" "$transmission_port""

				else

					# run tmux attached to transmission, specifying listening interface
					/usr/bin/script /home/nobody/typescript --command "/usr/bin/tmux new-session -d -s rt -n transmission /usr/bin/transmission-daemon "--foreground" "--config-dir" "/config" "--allowed" "${WHITELIST}" "--bind-address-ipv4" "${transmission_ip}""

				fi

				echo "[info] transmission started"
				

			fi

			# set transmission ip and port to current vpn ip and port (used when checking for changes on next run)
			transmission_ip="${vpn_ip}"
			transmission_port="${VPN_INCOMING_PORT}"

			# reset triggers to negative values
			transmission_running="false"
			ip_change="false"
			port_change="false"

			if [[ "${DEBUG}" == "true" ]]; then

				echo "[debug] VPN incoming port is ${VPN_INCOMING_PORT}"
				echo "[debug] VPN IP is ${vpn_ip}"
				echo "[debug] transmission incoming port is ${transmission_port}"
				echo "[debug] transmissionn IP is ${transmission_ip}"

			fi

		else

			echo "[warn] VPN IP not detected, VPN tunnel maybe down"

		fi

		# if pia then throttle checks to 10 mins (to prevent hammering api for incoming port), else 30 secs
		if [[ "${VPN_PROV}" == "pia" ]]; then
			sleep 10m
		else
			sleep 30s
		fi

	done

fi
