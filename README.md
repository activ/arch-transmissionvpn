**Application**

[transmission](https://www.transmissionbt.com/)
[OpenVPN](https://openvpn.net/)
[Privoxy](http://www.privoxy.org/)

**Description**


**Build notes**

Latest stable transmission release from Arch Linux.
Latest stable OpenVPN release from Arch Linux repo.
Latest stable Privoxy release from Arch Linux repo.

**Usage**
```
docker run -d \
    --cap-add=NET_ADMIN \
    -p 9080:9080 \
    -p 9443:9443 \
    -p 8118:8118 \
    --name=<container name> \
    -v <path for data files>:/data \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=<yes|no> \
    -e VPN_USER=<vpn username> \
    -e VPN_PASS=<vpn password> \
    -e VPN_REMOTE=<vpn remote gateway> \
    -e VPN_PORT=<vpn remote port> \
    -e VPN_PROTOCOL=<vpn remote protocol> \
    -e VPN_DEVICE_TYPE=<tun|tap> \
    -e VPN_PROV=<pia|airvpn|custom> \
    -e STRONG_CERTS=<yes|no> \
    -e ENABLE_PRIVOXY=<yes|no> \
    -e LAN_NETWORK=<lan ipv4 network>/<cidr notation> \
    -e NAME_SERVERS=<name server ip(s)> \
    -e WHITELIST= <example 192.168.*.*> \
    -e DEBUG=<true|false> \
    -e PHP_TZ=<php timezone> \
    -e PUID=<uid for user> \
    -e PGID=<gid for user> \
    activ/arch-transmissionvpn
```

Please replace all user variables in the above command defined by <> with the correct values.

**Access ruTorrent (web ui)**

`http://<host ip>:9080/`

or

`https://<host ip>:9443/`

Username:- admin
Password:- rutorrent

**Access Privoxy**

`http://<host ip>:8118`



**AirVPN provider**

AirVPN users will need to generate a unique OpenVPN configuration
file by using the following link https://airvpn.org/generator/

1. Please select Linux and then choose the country you want to connect to
2. Save the ovpn file to somewhere safe
3. Start the delugevpn docker to create the folder structure
4. Stop delugevpn docker and copy the saved ovpn file to the /config/openvpn/ folder on the host
5. Start delugevpn docker
6. Check supervisor.log to make sure you are connected to the tunnel

**AirVPN example**
```
docker run -d \
    --cap-add=NET_ADMIN \
	-p 8112:8112 \
	-p 8118:8118 \
    --name=transmissionvpn \
    -v /root/docker/data:/data \
    -v /root/docker/config:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e VPN_ENABLED=yes \
    -e VPN_USER=<vpn username> \
    -e VPN_PASS=<vpn password> \
    -e VPN_REMOTE=nl.vpn.airdns.org \
    -e VPN_PORT=443 \
    -e VPN_PROTOCOL=udp \
    -e VPN_DEVICE_TYPE=tun \
    -e VPN_PROV=airvpn \
    -e ENABLE_PRIVOXY=yes \
    -e LAN_NETWORK=192.168.1.0/24 \
    -e NAME_SERVERS=8.8.8.8,8.8.4.4 \
    -e WHITELIST= <example 192.168.*.*> \
    -e DEBUG=false \
    -e PHP_TZ=CET \
    -e PUID=99 \
    -e PGID=100 \
    activ/arch-transmissionvpn
```

**Notes**

User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

```
id <username>
```

The STRONG_CERTS environment variable is used to define whether to use strong certificates and enhanced encryption ciphers when connecting to PIA (does not affect other providers).
___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Support forum](http://lime-technology.com/forum/index.php?topic=47832.0)