#!/bin/bash
# ########################################################
#  Version:     1.0
#  Author:      Pavol Kluka
#  Date:        2019/02/14
#  Platforms:   Linux
# ########################################################

# DIRECTORY VARIABLES
DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# BIN VARIABLES
BIN_RM="$( which rm )"
BIN_MV="$( which mv )"
BIN_CAT="$( which cat )"
BIN_GREP="$( which grep )"
BIN_CP="$( which cp )"
BIN_SED="$( which sed )"
BIN_CHOWN="$( which chown )"
BIN_WGET="$( which wget )"
BIN_CURL="$( which curl )"
BIN_MKDIR="$( which mkdir )"

# ARGUMENT VARIABLES
ARG_PACKAGE="$1"

# SPLUNK VARIABLES
SPL_USR="vagrant"

if [ -z "${ARG_PACKAGE}" ]
then
    echo "Argument ARG_PACKAGE ($ARG_PACKAGE) is missing."
    exit 1
fi

echo "Look for $ARG_PACKAGE in /tmp"

if [ ! -f "/tmp/$ARG_PACKAGE" ]
then
    echo "Splunk package in /tmp file not found!"
    exit 1
fi

sudo dpkg -i "/tmp/$ARG_PACKAGE"

sudo $BIN_CHOWN -R $SPL_USR:$SPL_USR /opt/splunk

$BIN_CAT >> /opt/splunk/etc/system/local/user-seed.conf << EOL
[user_info]
USERNAME = admin
HASHED_PASSWORD = \$6\$xv5pIvgVooAFaRom\$GYdSQXx4/0fVO32g7peg8VlVHecr2FjUr.qOoxMs1Ps0YXjn7rRcl9ef5Er66zyq2beAbrhVJnMacpNiCgyHa1

EOL

echo "Add Splunk user (vagrant) to adm group."
sudo usermod -aG adm vagrant
if [ -f "/opt/splunk/etc/system/local/web.conf" ]
then
	$BIN_CP -v /opt/splunk/etc/system/local/web.conf /opt/splunk/etc/system/local/web.conf.orig
fi
echo "[settings]" > /opt/splunk/etc/system/local/web.conf
echo "enableSplunkWebSSL = true" >> /opt/splunk/etc/system/local/web.conf
echo "HTTPS enabled for Splunk Web using self-signed certificate."

echo "[splunktcp]" > /opt/splunk/etc/system/local/inputs.conf
echo "[splunktcp://9997]" >> /opt/splunk/etc/system/local/inputs.conf
echo "index = main" >> /opt/splunk/etc/system/local/inputs.conf
echo "disabled = 0" >> /opt/splunk/etc/system/local/inputs.conf
echo "" >> /opt/splunk/etc/system/local/inputs.conf
echo "[udp://5514]" >> /opt/splunk/etc/system/local/inputs.conf
echo "index = main" >> /opt/splunk/etc/system/local/inputs.conf
echo "disabled = 0" >> /opt/splunk/etc/system/local/inputs.conf

echo "Enabled Splunk TCP input over 9997 and UDP traffic input over 5514."

echo "Set minimum free disk space from default 5000MB to 1000MB."
if [ -f "/opt/splunk/etc/system/local/server.conf" ]
then
	$BIN_CP -v /opt/splunk/etc/system/local/server.conf /opt/splunk/etc/system/local/server.conf.orig
	$BIN_SED -ie 's?minFreeSpace = 5000?minFreeSpace = 1000?g' /opt/splunk/etc/system/local/server.conf
else
	echo "[diskUsage]" > /opt/splunk/etc/system/local/server.conf
	echo "minFreeSpace = 1000" >> /opt/splunk/etc/system/local/server.conf
fi

sudo $BIN_CHOWN -R $SPL_USR:$SPL_USR /opt/splunk
sudo su $SPL_USR -c "/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt"

echo "Enable Splunk on boot and run under user: $SPL_USR."
sudo /opt/splunk/bin/splunk enable boot-start -user $SPL_USR

if [[ -f /opt/splunk/bin/splunk ]]
then
	echo "Move the index database to /vagrant/share/splunk-db"
	sudo su $SPL_USR -c "/opt/splunk/bin/splunk stop"
	sudo $BIN_MKDIR -p /vagrant/share/splunk-db
	sudo $BIN_CHOWN -R $SPL_USR:$SPL_USR /vagrant/share
	$BIN_CP -rvp /opt/splunk/var/lib/splunk/* /vagrant/share/splunk-db/
	$BIN_MV -v /opt/splunk/var/lib/splunk/ /opt/splunk/var/lib/splunk.old/
	$BIN_CP -v /opt/splunk/etc/splunk-launch.conf /opt/splunk/etc/splunk-launch.conf.orig

	echo "" >> /opt/splunk/etc/splunk-launch.conf
	echo "# SPLUNK INDEX DATABASE LOCATION" >> /opt/splunk/etc/splunk-launch.conf
	echo "SPLUNK_DB=/vagrant/share/splunk-db" >> /opt/splunk/etc/splunk-launch.conf
	echo "" >> /opt/splunk/etc/splunk-launch.conf
	echo "# Maybe solve problem with of index=_audit on unusable filesystem | Link: https://github.com/hpierce/docker-kali-splunk" >> /opt/splunk/etc/splunk-launch.conf
	echo "OPTIMISTIC_ABOUT_FILE_LOCKING = 1" >> /opt/splunk/etc/splunk-launch.conf

	echo "Move the index database finished."
	sudo su $SPL_USR -c "/opt/splunk/bin/splunk start"
	echo "Splunk Enterprise $($BIN_CAT /opt/splunk/etc/splunk.version | head -1) has been installed, configured, and started!"
else
	echo "Splunk Enterprise has FAILED install!"
fi
