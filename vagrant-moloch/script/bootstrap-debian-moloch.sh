#!/bin/bash
# ########################################################
#  Version:     1.1
#  Author:      Pavol Kluka
#  Date:        2018/03/20
#  Platforms:   Linux
# ########################################################

# SCRIPT VARIABLES
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# BIN VARIABLES
BIN_RM="$( which rm )"
BIN_MV="$( which mv )"
BIN_TR="$( which tr )"
BIN_CAT="$( which cat )"
BIN_GREP="$( which grep )"
BIN_AWK="$( which awk )"
BIN_TEE="$( which tee )"
BIN_CP="$( which cp )"
BIN_CD="$( which cd )"
BIN_MKDIR="$( which mkdir )"
BIN_CHOWN="$( which chown )"
BIN_CHMOD="$( which chmod )"
BIN_WGET="$( which wget )"
BIN_MOUNT="$( which mount )"
BIN_UMOUNT="$( which umount )"
BIN_IP="$( which ip )"
BIN_TAR="$( which tar )"
BIN_SED="$( which sed )"
BIN_FIND="$( which find )"

# DIRECTORY VARIABLES
DIR_MOLOCH_INSTALL="/usr/local/src"
DIR_MOLOCH="/data/moloch"

# FILE VARIABLES
FILE_ELASTIC_HEALTH="$( mktemp )"

# INSTALL CURL
sudo apt-get -y install curl
BIN_CURL="$( which curl )"

if [ -z "$BIN_CURL" ]
then
    URL_LATEST=$($BIN_WGET http://download.virtualbox.org/virtualbox/LATEST.TXT -O /tmp/latest.txt && $BIN_CAT /tmp/latest.txt)
else
    URL_LATEST=$($BIN_CURL http://download.virtualbox.org/virtualbox/LATEST.TXT)
fi

# URL VARIABLES
if [ ! -z "$URL_LATEST" ]
then
    URL_VBOX_ADDON="http://download.virtualbox.org/virtualbox/$URL_LATEST/VBoxGuestAdditions_$URL_LATEST.iso"
else
    echo "URL_VBOX_ADDON    $URL_VBOX_ADDON"
fi

# Updating repository
echo "Update system"
sudo apt-get update && sudo apt-get -y upgrade
sudo apt-get -y autoremove

echo "Config Locale (/etc/environment)."
sudo $BIN_CP -v /etc/environment /etc/environment.orig
sudo $BIN_CAT >> /etc/environment <<EOL

LANGUAGE=en_US.UTF-8
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOL

echo "Install and config ntpddate."
sudo apt-get -y install ntpdate
sudo $BIN_CAT > /etc/cron.hourly/ntpdate <<EOL
#!/bin/bash
ntpdate 0.sk.pool.ntp.org 0.europe.pool.ntp.org 2.europe.pool.ntp.org

EOL
sudo chmod +x /etc/cron.hourly/ntpdate

echo "Set timezone."
timedatectl set-timezone Europe/Bratislava

echo "Install dnsutils and net toos."
sudo apt-get -y install dnsutils net-tools mc tcpdump apt-transport-https ca-certificates git

# Install dependencies for VBoxGuestAdditions
echo "Install dependencies for VBoxGuestAdditions."
sudo apt-get -y install build-essential linux-headers-$(uname -r) dkms
# Install latest VBoxGuestAdditions
echo "Download latest VBoxGuestAdditions ($URL_LATEST)."
FILE_ISO="$SCRIPT_DIR/VBoxGuestAdditions_latest.iso"
echo "FILE_ISO  $FILE_ISO"
$BIN_WGET -q -O $FILE_ISO $URL_VBOX_ADDON
if [ -s "$FILE_ISO" ]
then
    echo "Mount VBoxGuestAdditions.iso to /mnt."
    sudo $BIN_MOUNT -o loop $FILE_ISO /mnt
    echo "Create dir /tmp/VBoxGuestAdditions."
    sudo $BIN_MKDIR -p /tmp/VBoxGuestAdditions
    echo "Copy content of /mnt/* to /tmp/VBoxGuestAdditions."
    sudo $BIN_CP -vr /mnt/* /tmp/VBoxGuestAdditions
    cd /tmp/VBoxGuestAdditions
    echo "Run VBoxLinuxAdditions.run and after finished delete /tmp/VBoxGuestAdditions and unmount /mnt."
    sudo ./VBoxLinuxAdditions.run && cd && $BIN_RM -rf /tmp/VBoxGuestAdditions
    sudo $BIN_UMOUNT /mnt
    echo "Add Vagrant user to vboxfs group."
    sudo usermod -aG $($BIN_GREP 'vboxsf' /etc/group | $BIN_AWK -F ':' '{print $1}') vagrant
else
    echo "File $FILE_ISO doesn't exist"
fi

# MOLOCH SECTION
INTERFACE_NAT="$($BIN_IP addr | $BIN_GREP -E '^2:' | $BIN_GREP -Eo '[a-z]{3}[0-9]{1}')"
INTERFACE_CAPTURE="$($BIN_IP addr | $BIN_GREP -E '^3:' | $BIN_GREP -Eo '[a-z]{3}[0-9]{1}')"
echo "Prepare the network interface ($INTERFACE_CAPTURE) as capture card, turning off any IP address and the offloading features".
sudo $BIN_MV -v /etc/network/interfaces /etc/network/interfaces.orig
sudo $BIN_CAT > /etc/network/interfaces <<EOL
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface NAT
allow-hotplug $INTERFACE_NAT
iface $INTERFACE_NAT inet dhcp

# The secondary network interface HostOnly
allow-hotplug $INTERFACE_CAPTURE
iface $INTERFACE_CAPTURE inet manual
    up ip link set \$IFACE promisc on arp off up
    down ip link set \$IFACE promisc off down
    post-up ethtool -G \$IFACE rx 4096; for i in rx tx sg tso ufo gso gro lro; do eththool -K \$IFACE \$i off; done
    post-up echo1 > /proc/sys/net/ipv6/conf/\$IFACE/disable_ipv6

EOL

echo "Install missing tools: sudo less software-properties-common vim unzip."

echo "Install Open JDK 8"
sudo apt install -y openjdk-8-jre

echo "Download NodeSource Node.js 8.x source.list and install nodejs."
$BIN_CURL -sL https://deb.nodesource.com/setup_8.x | sudo bash -
sudo apt-get install -y nodejs

echo "Installed version of Node.js $(node -v)."
echo "Installed version of npm $(npm -v)."

# Elasticsearch stuff
# For Elasticsearch >= 7.x
# https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.1.0-amd64.deb
# ES_DEB="elasticsearch-7.1.0-amd64.deb"
# ES_VER="$(echo $ES_DEB | $BIN_AWK -F '-' '{print $2}')"
# https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.7.1.deb
ES_DEB="elasticsearch-6.7.1.deb"
ES_VER="$(echo $ES_DEB | $BIN_AWK -F '-' '{print $2}' | $BIN_GREP -Eo '\d\.\d\.\d')"
echo "Download Elasticsearch v$ES_VER and install it."
sudo $BIN_WGET -q -O /tmp/$ES_DEB https://artifacts.elastic.co/downloads/elasticsearch/$ES_DEB
sudo dpkg -i /tmp/$ES_DEB

echo "Enable Elasticsearch service on boot and start it."
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
STAT_ELASTIC="$(systemctl status elasticsearch.service | $BIN_AWK '/Active:/ {print $3}'|tr -d '(|)')"
while [[ "$STAT_ELASTIC" != "running" ]]
do
    echo "Waiting for elasticsearch.service ($STAT_ELASTIC)."
    sleep 5
    STAT_ELASTIC="$(systemctl status elasticsearch.service | $BIN_AWK '/Active:/ {print $3}'|tr -d '(|)')"
done
sudo systemctl stop elasticsearch
systemctl status elasticsearch

echo "Go to folder /usr/local/src and download moloch from GitHub"
cd $DIR_MOLOCH_INSTALL
sudo wget -q4 http://github.com/aol/moloch/archive/master.zip
sudo unzip master.zip

cd $DIR_MOLOCH_INSTALL/moloch-master/
echo "Execute easybutton.sh."
sudo ./easybutton-build.sh

echo "Run sudo make install."
sudo make install

echo "Create variables for moloch configuration."
MOLOCH_INTERFACE="$($BIN_IP addr | $BIN_GREP -E '^3:' | $BIN_GREP -Eo '[a-z]{3}[0-9]{1}')"
MOLOCH_LOCALELASTICSEARCH="yes"
MOLOCH_ELASTICSEARCH='http://127.0.0.1:9200'
MOLOCH_PASSWORD="admin"
MOLOCH_INET="yes"

echo "Make backup of /data/moloch/bin/Configure."
sudo $BIN_MV -v $DIR_MOLOCH/bin/Configure $DIR_MOLOCH/bin/Configure.orig
echo "Prepare moloch Configure for make install."
sudo $BIN_SED -e 's?read -r MOLOCH_INTERFACE?MOLOCH_INTERFACE='${MOLOCH_INTERFACE}'?g' -e 's?read -r MOLOCH_LOCALELASTICSEARCH?MOLOCH_LOCALELASTICSEARCH='${MOLOCH_LOCALELASTICSEARCH}'?g' -e 's?read -r MOLOCH_PASSWORD?MOLOCH_PASSWORD='${MOLOCH_PASSWORD}'?g' -e 's?MOLOCH_ELASTICSEARCH="http://localhost:9200"?MOLOCH_ELASTICSEARCH='${MOLOCH_ELASTICSEARCH}'?g' -e 's?read -r MOLOCH_INET?MOLOCH_INET='${MOLOCH_INET}'?g' -e 's?ES_VERSION=6.5.4?ES_VERSION='${ES_VER}'?g' -e 's?wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-${ES_VERSION}.deb?wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-oss-'${ES_VERSION}'-amd64.deb?g' $DIR_MOLOCH/bin/Configure.orig | sudo $BIN_TEE $DIR_MOLOCH/bin/Configure.new
sudo $BIN_CP -v $DIR_MOLOCH/bin/Configure.new $DIR_MOLOCH/bin/Configure

sudo $BIN_CHMOD 0755 $DIR_MOLOCH/bin/Configure
echo "Run make install is ready."
sudo make config

echo "Enable Moloch Viewer and Elasticsearch on boot."
sudo systemctl enable molochviewer.service
sudo systemctl enable elasticsearch.service

echo "Starting & preparing Elasticsearch."
sudo systemctl start elasticsearch.service

STAT_ELASTIC="$(systemctl status elasticsearch.service | $BIN_AWK '/Active:/ {print $3}'|tr -d '(|)')"
while [[ "$STAT_ELASTIC" != "running" ]]
do
    echo "Waiting for elasticsearch.service ($STAT_ELASTIC)."
    sleep 2
    STAT_ELASTIC="$(systemctl status elasticsearch.service | $BIN_AWK '/Active:/ {print $3}'|tr -d '(|)')"
done

echo "Elasticsearch service: $STAT_ELASTIC."
echo "Init Database."
sudo $BIN_WGET -q http://127.0.0.1:9200/_cluster/health -O $FILE_ELASTIC_HEALTH
STAT_DB=$(sudo $BIN_GREP -oP "(?<=status\"\:\").*?(?=\")" $FILE_ELASTIC_HEALTH)
while [[ "$STAT_DB" != "green" ]]
do
    echo "Waiting for Elasticsearch Database status. ($STAT_DB)."
    sleep 2
    sudo $BIN_WGET -q http://127.0.0.1:9200/_cluster/health -O $FILE_ELASTIC_HEALTH
    STAT_DB=$(sudo $BIN_GREP -oP "(?<=status\"\:\").*?(?=\")" $FILE_ELASTIC_HEALTH)
done

sudo $DIR_MOLOCH/db/db.pl http://127.0.0.1:9200 init

echo "Create admin account for Moloch."
sudo $DIR_MOLOCH/bin/moloch_add_user.sh admin "Admin User" "admin" --admin

echo "Edit Moloch service to waiting for Elasticsearch service."
sudo $BIN_MV -v /etc/systemd/system/molochviewer.service /etc/systemd/system/molochviewer.service.orig
sudo $BIN_CAT >> /etc/systemd/system/molochviewer.service <<EOL
[Unit]
Description=Moloch Viewer
After=network.target elasticsearch.service
Requires=network.target elasticsearch.service

[Service]
Type=simple
Restart=on-failure
StandardOutput=tty
EnvironmentFile=-/data/moloch/etc/molochviewer.env
ExecStart=/bin/sh -c 'sleep 5 && /data/moloch/bin/node viewer.js -c /data/moloch/etc/config.ini ${OPTIONS} >> /data/moloch/logs/viewer.log 2>&1'
WorkingDirectory=/data/moloch/viewer

[Install]
WantedBy=multi-user.target

EOL
sudo $BIN_CHMOD 0644 /etc/systemd/system/molochviewer.service
sudo $DIR_MOLOCH/bin/Configure --wise
sudo systemctl daemon-reload
sudo systemctl enable molochwise.service

echo "Make backup of /data/moloch/etc/config.ini."
MOLOCH_CONFIG_PCAPDIR="/vagrant/share/pcap"
MOLOCH_CONFIG_USER="vagrant"
MOLOCH_CONFIG_GROUP="vagrant"

sudo $BIN_MV -v $DIR_MOLOCH/etc/config.ini $DIR_MOLOCH/etc/config.ini.orig
echo "Change pcapDir, dropUser, dropGroup in /data/moloch/etc/config.ini."
sudo $BIN_SED -e 's?pcapDir = /data/moloch/raw?pcapDir = '${MOLOCH_CONFIG_PCAPDIR}'?g' -e 's?dropUser=nobody?dropUser='${MOLOCH_CONFIG_USER}'?g' -e 's?dropGroup=daemon?dropGroup='${MOLOCH_CONFIG_GROUP}'?g' $DIR_MOLOCH/etc/config.ini.orig | sudo $BIN_TEE $DIR_MOLOCH/etc/config.ini

echo "Start Moloch Viewer service."
sudo systemctl start molochviewer.service

echo "Start Moloch Wise service."
sudo systemctl start molochwise.service

systemctl status elasticsearch.service
systemctl status molochviewer.service
systemctl status molochwise.service

echo "Create script for processing PCAP files."
sudo $BIN_CAT >> /etc/cron.d/pcap-upload.sh <<EOL
#!/bin/bash
# ########################################################
#  Version:     1.0
#  Author:      Pavol Kluka
#  Date:        2019/01/31
#  Platforms:   Linux
# ########################################################

# SCRIPT VARIABLES
SCRIPT_DIR="\$( cd "\$( dirname "\${BASH_SOURCE[0]}" )" && pwd )"

# BIN VARIABLES
BIN_MV="\$( which mv )"
BIN_CAT="\$( which cat )"
BIN_GREP="\$( which grep )"
BIN_PGREP="\$( which pgrep )"
BIN_AWK="\$( which awk )"
BIN_CP="\$( which cp )"
BIN_CD="\$( which cd )"
BIN_MKDIR="\$( which mkdir )"
BIN_FIND="\$( which find )"
BIN_CHOWN="\$( which chown )"
BIN_LOGGER="\$( which logger )"

# LOG VARIABLES
LOG_SCRIPT_NAME="\$( basename \$0 )"

# DIRECTORY VARIABLES
DIR_PCAP_NEW="/vagrant/share/pcap/new"
DIR_PCAP_READY="/vagrant/share/pcap/ready"

# FILE VARIABLES
FILE_PCAP_LIST="\$( mktemp )"

\$BIN_LOGGER -sp user.info -t \$LOG_SCRIPT_NAME "PCAP-UPLOAD: Check if share folder exist."
if [ -d "/vagrant/share" ]
then
    if [ ! -d "\$DIR_PCAP_READY" ] || [ ! -d "\$DIR_PCAP_NEW" ]
    then
        \$BIN_MKDIR -pv "\$DIR_PCAP_NEW"
        \$BIN_MKDIR -pv "\$DIR_PCAP_READY"
        \$BIN_CHOWN -R vagrant /vagrant/share
    else
        \$BIN_LOGGER -sp user.info -t \$LOG_SCRIPT_NAME "PCAP-UPLOAD: Share folders exists."
    fi
else
    \$BIN_LOGGER -sp user.info -t \$LOG_SCRIPT_NAME "PCAP-UPLOAD: Share folders doesn't exist. Folder was created."
    \$BIN_MKDIR -pv "\$DIR_PCAP_NEW"
    \$BIN_MKDIR -pv "\$DIR_PCAP_READY"
    \$BIN_CHOWN -R vagrant /vagrant/share
fi

if [[ \$(\$BIN_PGREP -f \$LOG_SCRIPT_NAME) ]]
then
    sudo \$BIN_FIND \$DIR_PCAP_NEW -type f -exec file {} \; | \$BIN_AWK -F ':' '/pcap/ {print \$1}' > \$FILE_PCAP_LIST
    while read PCAP
    do
        PCAP_FILE="\$(echo \$PCAP | \$BIN_AWK -F '/' '{print \$NF}')"
        \$BIN_LOGGER -sp user.info -t \$LOG_SCRIPT_NAME "PCAP-UPLOAD: Processing file \$DIR_PCAP_READY/\$PCAP_FILE."
        sudo \$BIN_MV -v \$PCAP \$DIR_PCAP_READY/
        sudo /data/moloch/bin/moloch-capture -r \$DIR_PCAP_READY/\$(echo \$PCAP | \$BIN_AWK -F '/' '{print \$NF}')
        sudo \$BIN_CHOWN -R vagrant:vagrant \$DIR_PCAP_READY
        \$BIN_LOGGER -sp user.info -t \$LOG_SCRIPT_NAME "PCAP-UPLOAD: File \$DIR_PCAP_READY/\$PCAP_FILE is ready."
    done < \$FILE_PCAP_LIST
else
    \$BIN_LOGGER -sp user.info -t \$LOG_SCRIPT_NAME "PCAP-UPLOAD: is running."
fi

EOL

sudo $BIN_CHMOD +x /etc/cron.d/pcap-upload.sh

echo "Add script to root crontab."
sudo echo "*/1 * * * * root /etc/cron.d/pcap-upload.sh" >> /etc/crontab

echo "Well done."
