#!/bin/bash
# ########################################################
#  Version:     1.0
#  Author:      Pavol Kluka
#  Date:        2019/02/14
#  Platforms:   Linux 
#  Link:		https://github.com/PaloAltoNetworks/minemeld-ansible
# ########################################################

# DIRECTORY VARIABLES
DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# BIN VARIABLES
BIN_RM="$( which rm )"
BIN_MV="$( which mv )"
BIN_CAT="$( which cat )"
BIN_CP="$( which cp )"
BIN_WGET="$( which wget )"
BIN_MKDIR="$( which mkdir )"
BIN_USERMOD="$( which usermod )"

sudo apt-get update && sudo apt-get upgrade
echo "Install gcc, git, python2.7-dev, libffi-dev, libssl-dev."
sudo apt-get install -y gcc git python2.7-dev libffi-dev libssl-dev

echo "Download and install python pip."
$BIN_WGET -q https://bootstrap.pypa.io/get-pip.py
sudo -H python get-pip.py

echo "Install ansible."
sudo -H pip install ansible

echo "Clone PaloAlto Networks minemeld-ansible."
git clone https://github.com/PaloAltoNetworks/minemeld-ansible.git

echo "Install Minemeld - stable version."
cd minemeld-ansible
ansible-playbook -K -e "minemeld_version=master" -i 127.0.0.1, local.yml
echo "Add vagrant user to minemeld group."
sudo /usr/sbin/usermod -a -G minemeld vagrant

echo "Check if minemeld running."
sudo -u $BIN_USERMOD /opt/minemeld/engine/current/bin/supervisorctl -c /opt/minemeld/supervisor/config/supervisord.conf status

echo "Finish."