#!/bin/sh

for interface in $(networksetup -listnetworkserviceorder | grep Hardware | awk '/Wi-Fi/ { print $NF }' | awk -F ")" '{ print $1 }')
do
    echo "Disconnecting Wi-Fi from BYOD and Guest Network"
    networksetup -removepreferredwirelessnetwork $interface MAGS-BYOD
    networksetup -removepreferredwirelessnetwork $interface MAGS-Guest
done