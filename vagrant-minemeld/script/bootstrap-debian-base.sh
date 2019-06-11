#!/bin/bash
# ########################################################
#  Version:     1.0
#  Author:      Pavol Kluka
#  Date:        2019/02/14
#  Platforms:   Linux
# ########################################################

# SCRIPT VARIABLES
DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# BIN VARIABLES
BIN_RM="$( which rm )"
BIN_MV="$( which mv )"
BIN_CAT="$( which cat )"
BIN_GREP="$( which grep )"
BIN_TAIL="$( which tail )"
BIN_AWK="$( which awk )"
BIN_TEE="$( which tee )"
BIN_CP="$( which cp )"
BIN_CD="$( which cd )"
BIN_WC="$( which wc )"
BIN_MKDIR="$( which mkdir )"
BIN_CHOWN="$( which chown )"
BIN_CHMOD="$( which chmod )"
BIN_WGET="$( which wget )"
BIN_MOUNT="$( which mount )"
BIN_UMOUNT="$( which umount )"
BIN_IP="$( which ip )"
BIN_IFCONFIG="$( which ifconfig )"
BIN_TAR="$( which tar )"
BIN_SED="$( which sed )"
BIN_FIND="$( which find )"

# INSTALL CURL
sudo apt-get -y install curl
BIN_CURL="$( which curl )"

if [ -z "$BIN_CURL" ]
then
    URL_LATEST=$($BIN_WGET -q http://download.virtualbox.org/virtualbox/LATEST.TXT -O /tmp/latest.txt && $BIN_CAT /tmp/latest.txt)
else
    URL_LATEST=$($BIN_CURL -s http://download.virtualbox.org/virtualbox/LATEST.TXT)
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

echo "Install wanted tools."
apt-get -y install dnsutils net-tools apt-transport-https ca-certificates

echo "Disable IPv6."
$BIN_CP -v /etc/sysctl.conf /etc/sysctl.conf.orig
$BIN_CAT >> /etc/sysctl.conf <<EOL

# Disable IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOL
sysctl -p

# Install dependencies for VBoxGuestAdditions
echo "Install dependencies for VBoxGuestAdditions."
sudo apt-get -y install build-essential linux-headers-$(uname -r) dkms
# Install latest VBoxGuestAdditions
echo "Download latest VBoxGuestAdditions ($URL_LATEST)."
FILE_ISO="$DIR_SCRIPT/VBoxGuestAdditions_latest.iso"
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
    $BIN_RM -rf $FILE_ISO
else
    echo "File $FILE_ISO doesn't exist"
fi

echo "Maybe it is done..."
