#!/bin/bash

# Author:   TazNZ - Jordan Noovao
# Name:     AllowEveryonePrinterAdmin.sh
#
# Purpose:  This script enables all local users admin access to Printers using the lpadmin group in macOS.
# Tested within Jamf Pro and Microsoft Intune.

/bin/echo "Authorize non-admin users (everyone) access to the Printing system pref"
        /usr/bin/security authorizationdb read  system.preferences.printing > /tmp/system.preferences.printing.plist
        /usr/bin/defaults write /tmp/system.preferences.printing.plist group everyone
        /usr/bin/security authorizationdb write system.preferences.printing < /tmp/system.preferences.printing.plist
        /bin/echo "Adding the group everyone to the lpadmin group"
        /usr/sbin/dseditgroup -o edit -n /Local/Default -a "everyone" -t group lpadmin
