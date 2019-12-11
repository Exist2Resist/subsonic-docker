#!/bin/bash
#Set new Local Time Zone.
rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/$TZ /etc/localt

#Find subsonic latest version.
SUB_VER=$(curl http://www.subsonic.org/pages/download.jsp 2>&1 | grep rpm | awk -F'"' '/download/ { print $2 }' | awk -F'=' ' { print $2 } ')
SUB_RHEL="https://s3-eu-west-1.amazonaws.com/subsonic-public/download/"$SUB_VER

yum install -y epel-release
yum update -y
yum install -y java-1.8.0-openjdk wget
cd /tmp
wget -q $SUB_RHEL
yum install --nogpgcheck -y $SUB_VER

USERID=${PUID:-99}
GROUPID=${GUID:-100}

groupmod -g $GROUPID users
usermod -u $USERID nobody
usermod -g $USERID nobody
usermod -d /home nobody
gpasswd --add nobody audio
mkdir /music /podcasts /playlists /subsonic
chown -R nobody:users /music /podcasts /playlists /subsonic
chmod -R 755 /music /podcasts /playlists /subsonic  
mkdir -p /subsonic/transcode
chown -R root:root /subsonic/transcode
cp /var/subsonic/transcode/* /subsonic/transcode/
rm -rf /var/subsonic

echo "[ "$(date)" ] Subsonic is version "$SUB_VER

cat <<'EOF' > /usr/local/bin/start.sh
#!/bin/bash
##Start boot script
TIMEZONE=${TZ:-America/Edmonton}

rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime

USERID=${PUID:-99}
GROUPID=${GUID:-100}

groupmod -g $GROUPID users
usermod -u $USERID nobody
usermod -g $USERID nobody
usermod -d /home nobody
chown -R nobody:users /music /podcasts /playlists /subsonic 
chmod -R 755 /music /podcasts /playlists /subsonic 

chown -R root:root /subsonic/jetty/1944/webapp /var/subsonic/transcode
EOF

cat <<'EOT' > /etc/systemd/system/startup.service
[Unit]
Description=Startup Script that sets Subsonic folder permissions.
Before=subsonic.service

[Service]
Type=simple
ExecStart=/usr/local/bin/start.sh
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOT

cat <<'EOT' > /etc/systemd/system/subsonic.service
[Unit]
Description=Subsonic service.
Before=post.service

[Service]
Type=forking
User=nobody
Group=users
ExecStart=/usr/bin/subsonic --max-memory=300 --home=/subsonic --default-music-folder=/music --default-podcast-folder=/podcasts --default-playlist-folder=/playlists
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOT

cat <<'EOF' > /usr/local/bin/post.sh
#!/bin/bash
#Change Jetty permissions to prevent server vulnerability.
chown -R root:root /subsonic/jetty/1944/webapp
EOF

cat <<'EOF' > /etc/systemd/system/post.service
Description=Post Startup Script that sets Subsonic folder permissions.
After=subsonic.service

[Service]
Type=simple
ExecStart=/usr/local/bin/post.sh
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOF

cat <<'EOF' > /usr/local/bin/update.sh
#!/bin/bash
SUB_VER=$(curl http://www.subsonic.org/pages/download.jsp 2>&1 | grep rpm | awk -F'"' '/download/ { print $2 }' | awk -F'=' ' { print $2 } ')
SUB_RHEL="https://s3-eu-west-1.amazonaws.com/subsonic-public/download/"$SUB_VER

#echo "[ "$(date)" ] Subsonic is version "$SUB_VER > /subsonic/subsonic-docker.log
EOF

##crontab 
echo "0  0    * * *   root    /usr/local/bin/update.sh" >> /etc/crontab

cd /
rm -rf /tmp/*
yum clean all

#Enable Services
systemctl enable startup.service
systemctl enable subsonic.service
systemctl enable post.service