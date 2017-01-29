#!/bin/bash

# get username and password from credentials file
USERNAME=$(sed -n '1p' /config/openvpn/credentials.conf)
PASSWORD=$(sed -n '2p' /config/openvpn/credentials.conf)

# lookup the dynamic pia incoming port (response in json format)
VPN_INCOMING_PORT=`curl --connect-timeout 10 --max-time 20 --retry 6 --retry-max-time 120 -s -d "user=$USERNAME&pass=$PASSWORD&client_id=$client_id&local_ip=$vpn_ip" https://www.privateinternetaccess.com/vpninfo/port_forward_assignment | head -1 | grep -Po "[0-9]*"`