#!/bin/bash

# Author:   TazNZ - Jordan Noovao
# Name:     EnableLocationServices.sh
#
# Purpose:  This script turns enables Location Services on macOS.
# This has been tested on macOS Mojave, Catalina and Big Sur.
# Future macOS versions might not work. Please test first!


uuid=$("/usr/sbin/system_profiler" SPHardwareDataType | grep "Hardware UUID" | awk '{ print $3 }')
prefDomain="com.apple.locationd.$uuid"
byHostPath="/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd"

# read booleans
ls_enabled_uuid=$(sudo -u "_locationd" defaults -currentHost read "${prefDomain}" LocationServicesEnabled)
ls_enabled_byhost=$(sudo defaults read "${byHostPath}" LocationServicesEnabled)

# process booleans
if [[ $ls_enabled_uuid && $ls_enabled_byhost ]]; then
    echo "Location Services are already enabled."
else
    # set booleans
    sudo -u "_locationd" defaults -currentHost write "${prefDomain}" LocationServicesEnabled -int 1
    sudo defaults write "${byHostPath}" LocationServicesEnabled -int 1
fi
