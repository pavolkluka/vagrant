#!/bin/bash
# ########################################################
#  Version:     1.0
#  Author:      Pavol Kluka
#  Date:        2018/03/20
#  Platforms:   Linux
# ########################################################

# SCRIPT VARIABLES
DIR_SCRIPT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# BIN VARIABLES
BIN_TR="$( which tr )"
BIN_AWK="$( which awk )"
BIN_GREP="$( which grep )"
BIN_VAGRANT="$( which vagrant )"

if [ -z "$BIN_VAGRANT" ]
then
    echo "Vagrant is requirement."
    exit 1
fi

# ARRAY DEFINITION
declare -a ARR_BOXES=(
	"debian/stretch64"
	)

# LOOP ARRAY AND CHECK VAGRANT BOXES
for BOX in "${ARR_BOXES[@]}"
do
    echo "Check if exist $BOX vagrant box."
    # STRING VARIABLES
    STR_BOX="$BOX"
    STR_PROVIDER=""
    STR_BOX_VER=""

    # OUTPUT VARIABLES
    OUT_LIST="$($BIN_VAGRANT box list | $BIN_GREP $STR_BOX)"

    if [ ! -z "$OUT_LIST" ]
    then
        echo "Vagrant box $BOX exist."
        STR_PROVIDER="$(echo "$OUT_LIST" | $BIN_GREP $STR_BOX | $BIN_AWK '{print $2}' | $BIN_AWK -F ',' '{print $1}' | $BIN_TR -d '(|)')"
        STR_BOX_VER="$(echo "$OUT_LIST" | $BIN_GREP $STR_BOX | $BIN_GREP -Eo '[0-9]+\.[0-9]+\.[0-9]+')"
        echo "Box: $STR_BOX."
        echo "Box provider: $STR_PROVIDER."
        echo "Box version: $STR_BOX_VER."
    else
        echo "Vagrant box $BOX doesn't exist."
        echo "Download vagrant box $BOX."
        $BIN_VAGRANT box add $BOX
    fi
done
