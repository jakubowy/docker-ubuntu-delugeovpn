FROM ubuntu:bionic

#RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
#	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
#ENV LANG en_US.utf8



#FOR DEVEL
RUN apt-get update && apt-get install -y iproute2 curl iputils-ping vim psmisc net-tools tcpdump && rm -rf /var/lib/apt/lists/*
# CORE PCKGS
#RUN echo "deb http://ppa.launchpad.net/deluge-team/ppa/ubuntu bionic main" > /etc/apt/sources.list.d/deluge-team-ubuntu-ppa-bionic.list
RUN apt-get update &&\
	apt-get install -y software-properties-common &&\
	add-apt-repository -y ppa:deluge-team/ppa &&\
	apt-get update &&\
	apt-get install -y wget openvpn unzip deluged deluge-web deluge-console iptables &&\
	apt-get purge -y software-properties-common &&\
	mkdir /dockerfiles && cd /dockerfiles &&\
	wget https://www.privateinternetaccess.com/openvpn/openvpn.zip &&\
	unzip -o openvpn.zip  Sweden.ovpn crl.rsa.2048.pem ca.rsa.2048.crt &&\
	sed -i 's|auth-user-pass|auth-user-pass /dockerfiles/credentials.txt|g' Sweden.ovpn &&\
	rm -rf /var/lib/apt/lists/*

#RUN groupadd -g 1000 appuser
# DELUGE PASSWORDLESS
ADD files/deluge-all.js /usr/lib/python2.7/dist-packages/deluge/ui/web/js/deluge-all.js
ADD files/auth.py /usr/lib/python2.7/dist-packages/deluge/ui/web/auth.py   

# RUNSCRIPTS
ADD files/bootstrap.sh /dockerfiles/bootstrap.sh
ADD files/updatedeluge.sh /dockerfiles/updatedeluge.sh
RUN chmod 0770 /dockerfiles/bootstrap.sh /dockerfiles/updatedeluge.sh

# CRON FOR PIA
ADD files/crontab /etc/cron.d/cronjob
RUN chmod 0644 /etc/cron.d/cronjob
RUN crontab /etc/cron.d/cronjob
RUN cron

EXPOSE 8112
#USER appuser
CMD ["/dockerfiles/bootstrap.sh"]
	

