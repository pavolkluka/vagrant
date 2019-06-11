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

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y gcc git python2.7-dev libffi-dev libssl-dev
wget https://bootstrap.pypa.io/get-pip.py
sudo -H python get-pip.py
sudo -H pip install ansible
git clone https://github.com/PaloAltoNetworks/minemeld-ansible.git
cd minemeld-ansible
# need edit local.yml
ansible-playbook -K -i 127.0.0.1, local.yml
sudo /usr/sbin/usermod -a -G minemeld vagrant

sudo -u minemeld /opt/minemeld/engine/current/bin/supervisorctl -c /opt/minemeld/supervisor/config/supervisord.conf status
