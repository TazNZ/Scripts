#!/bin/bash

# Enable AirPort Admin Rights 

# Get the current AdminPowerToggle setting
currentAdminPowerToggleSetting=$(/usr/libexec/airportd prefs RequireAdminPowerToggle)

# Get the current AdminNetworkChange setting
currentAdminNetworkChangeSetting=$(/usr/libexec/airportd prefs RequireAdminNetworkChange)

# Get the current AdminIBSS setting
currentAdminIBSSSeting=$(/usr/libexec/airportd prefs RequireAdminIBSS)

# The settings should be on
# So check first if the settings are on
if [ "$currentAdminPower ToggleSetting" == "RequireAdminPowerToggle=NO" ] || [ "$currentAdminNetworkChangeSetting" == "RequireAdminNetworkChange=NO" ] || [ "$currentAdminIBSSSeting" == "RequireAdminIBSS=NO" ]; then

# Enable admin rights to disable or enable wifi, change ssid or create a wi-fi hotspot.

WIFI=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $NF}')

# RequireAdminPowerToggle
/usr/libexec/airportd $WIFI prefs RequireAdminPowerToggle=true

# RequireAdminNetworkChange
/usr/libexec/airportd $WIFI prefs RequireAdminNetworkChange=true

# RequireAdminIBSS
/usr/libexec/airportd $WIFI prefs RequireAdminIBSS=true

echo Admin rights are now enabled!

else

# Installed
/bin/echo "Airport Admin rights already enabled!"
fi