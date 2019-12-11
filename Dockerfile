FROM exist2resist/centos7
MAINTAINER admin@dataadnstoragesolutions.com

ENV TZ="America/Edmonton" PUID=99 GUID=100

COPY ./install.sh /tmp/
COPY ./functions /etc/init.d/
RUN rm -rf /etc/localtime && ln -s /usr/share/zoneinfo/America/Edmonton /etc/localtime
RUN chmod 755 /tmp/install.sh && /tmp/install.sh && rm -rf /tmp/*

EXPOSE 4040
VOLUME ["/subsonic","/music","/podcasts","/playlists"]
CMD ["/usr/local/bin/systemctl"]