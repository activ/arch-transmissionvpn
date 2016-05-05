FROM binhex/arch-openvpn 
MAINTAINER none

ADD setup/*.conf /etc/supervisor/conf.d/
ADD setup/root/*.sh /root/
ADD apps/root/*.sh /root/
ADD apps/nobody/*.sh /home/nobody/

RUN chmod +x /root/*.sh /home/nobody/*.sh && \
	/bin/bash /root/install.sh

VOLUME ["/config"]
VOLUME /data

EXPOSE 9091/tcp
CMD ["/bin/bash", "/root/init.sh"]

