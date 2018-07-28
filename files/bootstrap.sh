#!/bin/bash
cd /dockerfiles
echo "Creating deluged user with uid $DELUGED_UID"
useradd -m -u $DELUGED_UID deluged
adduser deluged root

echo "Owning homedir"
chown -R deluged:deluged /home/deluged

echo "Creating PIA ovpn credentials user: $PIA_USER password: $PIA_PASS"
echo -e "$PIA_USER\n$PIA_PASS" > credentials.txt && chmod 0400 credentials.txt

echo "Starting OVPN"
openvpn --config Sweden.ovpn --log-append /var/log/openvpn.log &
echo "Updating resolv.conf"
echo -e "nameserver 209.222.18.222\nnameserver 209.222.18.218" > /etc/resolv.conf

echo "Starting deluged - populating config files - killing deluged"
su deluged -c /usr/bin/deluged
sleep 5
su deluged -c "killall deluged"


echo "Creating deluged console user $DELUGE_CONSOLE_USER $DELUGE_CONSOLE_PASS"
su deluged -c 'echo "$DELUGE_CONSOLE_USER:$DELUGE_CONSOLE_PASS:10" >> /home/deluged/.config/deluge/auth'

#echo "Staring deluged daemon"
#su deluged -c "/usr/bin/deluged -l /home/deluged/deluged.log"

echo "Starting deluge-web daemon"
su deluged -c "/usr/bin/deluge-web -f --ssl"
sleep 5

echo "Set default console to connect to 127.0.0.1:58846"
sed -i 's/"default_daemon": ""/"default_daemon": "127.0.0.1:58846"/g' /home/deluged/.config/deluge/web.conf

#echo "200 isp2" >> /etc/iproute2/rt_tables
#172.17.0.3
#ip rule add from 172.17.0.3 dev eth0 table isp2
#ip route add default via 172.17.0.1 dev eth0 table isp2

ETH0IP=$(ip addr show eth0 |grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]/" |grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]")
ETH0SUBNET=$(echo $ETH0IP |cut -d '.' -f 1-3).0
ETH0GATEWAY=$(echo $ETH0IP |cut -d '.' -f 1-3).1
echo "Setting ip routes to allow remote traffic ip: $ETH0IP subnet: $ETH0SUBNET/24 gateway: $ETH0GATEWAY"
ip rule add table 128 from $ETH0IP
ip route add table 128 to $ETH0SUBNET/24 dev eth0
ip route add table 128 default via $ETH0GATEWAY


#echo "Setting up deluge iface and ports"
#/dockerfiles/updatedeluge.sh

echo "Exporting ENVs for cron"
echo -e "export PIA_USER=$PIA_USER\nexport PIA_PASS=$PIA_PASS\nexport DELUGE_CONSOLE_USER=$DELUGE_CONSOLE_USER\nexport DELUGE_CONSOLE_PASS=$DELUGE_CONSOLE_PASS\n" >> $HOME/.profile

echo "Starting cron"
cron


echo "Staring deluged daemon"
su deluged -c "/usr/bin/deluged -d -l /home/deluged/deluged.log"

