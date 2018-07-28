#!/usr/bin/env bash
# Source: http://www.htpcguides.com
# Adapted from https://github.com/blindpet/piavpn-portforward/
# Author: Mike
# Based on https://github.com/crapos/piavpn-portforward

# Set path for root Cron Job
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

USERNAME=piauser
PASSWORD=piapassword
VPNINTERFACE=tun0
VPNLOCALIP=$(ifconfig $VPNINTERFACE | awk '/inet / {print $2}' | awk 'BEGIN { FS = ":" } {print $(NF)}')
CURL_TIMEOUT=5
CLIENT_ID=$(uname -v | sha1sum | awk '{ print $1 }')

# set to 1 if using VPN Split Tunnel
SPLITVPN=""

DELUGEUSER=delconsoleuser
DELUGEPASS=password
DELUGEHOST=localhost

#get VPNIP
VPNIP=$(curl -m $CURL_TIMEOUT --interface $VPNINTERFACE "http://ipinfo.io/ip" --silent --stderr -)
echo $VPNIP

#request new port
PORTFORWARDJSON=$(curl -m $CURL_TIMEOUT --silent --interface $VPNINTERFACE  'https://www.privateinternetaccess.com/vpninfo/port_forward_assignment' -d "user=$USERNAME&pass=$PASSWORD&client_id=$CLIENT_ID&local_ip=$VPNLOCALIP" | head -1)
#trim VPN forwarded port from JSON
PORT=$(echo $PORTFORWARDJSON | awk 'BEGIN{r=1;FS="{|:|}"} /port/{r=0; print $3} END{exit r}')
echo $PORT  

TUNIP=$(ip addr show tun0 |grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9] peer" |awk '{print $2}')
#change deluge port on the fly

deluge-console "connect $DELUGEHOST:58846 $DELUGEUSER $DELUGEPASS; config --set random_port false"
deluge-console "connect $DELUGEHOST:58846 $DELUGEUSER $DELUGEPASS; config --set listen_ports ($PORT,$PORT)"
#deluge-console "connect $DELUGEHOST:58846 $DELUGEUSER $DELUGEPASS; config --set outgoing_ports ($PORT,$PORT)"
deluge-console "connect $DELUGEHOST:58846 $DELUGEUSER $DELUGEPASS; config --set listen_interface $TUNIP"
