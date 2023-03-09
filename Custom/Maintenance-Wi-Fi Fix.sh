#!/bin/bash
## Improve Wi-Fi with macOS and airport commands

## Turn Off Wi-Fi
networksetup -setairportpower Wi-Fi off
sleep 2

## Set join mode -- Options: Automatic, Preferred, Ranked, Recent, Strongest ## Keeps connection persistand on login screen
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport prefs JoinMode=Strongest JoinModeFallback=KeepLooking DisconnectOnLogout=NO

## Turn on Wi-Fi
sleep 2
networksetup -setairportpower Wi-Fi on
exit 0