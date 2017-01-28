#!/bin/bash

# if config file doesnt exist then copy stock config file
#if [[ ! -f /config/core.conf ]]; then
#	cp /home/nobody/transmission/core.conf /config/
#fi

# if vpn set to "no" then don't run openvpn
if [[ $VPN_ENABLED == "no" ]]; then

	echo "[info] VPN not enabled, skipping VPN tunnel local ip checks"

	transmission_ip=""

	# set listen interface ip address for transmission
#	sed -i -e 's~"listen_interface":\s*"[^"]*~"listen_interface": "'"${transmission_ip}"'~g' /config/core.conf

	# run transmission daemon
	echo "[info] All checks complete, starting Transmission..."
	/usr/bin/transmission-daemon "--foreground" "--config-dir" "/config" "--allowed" "${WHITELIST}" 

else

	echo "[info] VPN is enabled, checking VPN tunnel local ip is valid"

	# create pia client id (randomly generated)
	client_id=`head -n 100 /dev/urandom | md5sum | tr -d " -"`

	# run script to check ip is valid for tun0
	source /home/nobody/checkip.sh

	# set triggers to first run
	first_run="true"
	reload="false"

	# set empty values for port and ip
	transmission_port=""
	transmission_ip=""

	# set sleep period for recheck (in mins)
	sleep_period="5"

	# while loop to check ip and port
	while true; do

		# run scripts to identity vpn ip
		source /home/nobody/getvpnip.sh

		if [[ $first_run == "false" ]]; then

			# if current bind interface ip is different to tunnel local ip then re-configure transmission
			if [[ $transmission_ip != "$vpn_ip" ]]; then

				echo "[info] Transmission listening interface IP $transmission_ip and VPN provider IP different, reconfiguring for VPN provider IP $vpn_ip"

				# mark as reload required due to mismatch
				transmission_ip="${vpn_ip}"
				reload="true"

			else

				echo "[info] transmission listening interface IP $transmission_ip and VPN provider IP $vpn_ip match"

			fi

		else

			echo "[info] First run detected, setting Transmission listening interface $vpn_ip"

			# mark as reload required due to first run
			transmission_ip="${vpn_ip}"
			reload="true"

		fi

		if [[ $VPN_PROV == "pia" ]]; then

			if [[ $first_run == "false" ]]; then

				# run netcat to identify if port still open, use exit code
				if ! /usr/bin/nc -z -w 3 "${transmission_ip}" "${transmission_port}"; then

					echo "[info] transmission incoming port $transmission_port closed"

					# run scripts to identify vpn port
					source /home/nobody/getvpnport.sh

					echo "[info] Reconfiguring for VPN provider port $vpn_port"

					# mark as reload required due to mismatch
					transmission_port="${vpn_port}"
					reload="true"

				else

					echo "[info] Transmission incoming port $transmission_port open"

				fi

			else

				# run scripts to identify vpn port
				source /home/nobody/getvpnport.sh

				echo "[info] First run detected, setting transmission incoming port $vpn_port"

				if [[ ! $vpn_port =~ ^-?[0-9]+$ ]]; then
					echo "[warn] PIA incoming port is not an integer, downloads will be slow, does PIA remote gateway supports port forwarding?"
				fi

				# mark as reload required due to first run
				transmission_port="${vpn_port}"
				reload="true"

			fi

		fi

		if [[ $reload == "true" ]]; then

				# run transmission daemon
				echo "[info] All checks complete, starting transmission..."
				if [[ $VPN_PROV == "pia" ]]; then
					/usr/bin/transmission-daemon "--foreground" "--config-dir" "/config" "--allowed" "${WHITELIST}" "--bind-address-ipv4" "${transmission_ip}" "--peerport" "$transmission_port"
				else
			    	/usr/bin/transmission-daemon "--foreground" "--config-dir" "/config" "--allowed" "${WHITELIST}" "--bind-address-ipv4" "${transmission_ip}" 
				fi
		
		fi

		# reset triggers to negative values
		first_run="false"
		reload="false"

		echo "[info] Sleeping for ${sleep_period} mins before rechecking listen interface and port for PIA only"
		sleep "${sleep_period}"

	done

fi
