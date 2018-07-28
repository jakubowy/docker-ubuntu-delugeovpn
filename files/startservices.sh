#!/bin/bash

openvpn --config Sweden.ovpn  &
echo -e "nameserver 209.222.18.222\nnameserver 209.222.18.218" > /etc/resolv.conf
su deluged -c /usr/bin/deluged
sleep 5
su deluged -c "killall deluged"
su deluged -c 'echo "delconsoleuser:password:10" >> /home/deluged/.config/deluge/auth'
su deluged -c /usr/bin/deluged
su deluged -c "/usr/bin/deluge-web -f"
sed -i 's/"default_daemon": ""/"default_daemon": "127.0.0.1:58846"/g' /home/deluged/.config/deluge/web.conf

#echo "200 isp2" >> /etc/iproute2/rt_tables
#172.17.0.3
#ip rule add from 172.17.0.3 dev eth0 table isp2
#ip route add default via 172.17.0.1 dev eth0 table isp2

ip rule add table 128 from 172.17.0.3
ip route add table 128 to 172.17.0.0/24 dev eth0
ip route add table 128 default via 172.17.0.1

