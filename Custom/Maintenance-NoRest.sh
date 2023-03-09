#!/bin/bash
# This script helps alert users that their Mac has been on for 2 weeks or more and advises them to reboot.

# Grab icon image from specified URL and place into /tmp
/usr/bin/curl -s -o /tmp/lock_icon.png https://www.pikpng.com/pngl/b/555-5554942_restart-button-png.png
loggedInUser=$(stat -f%Su /dev/console)
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
windowType="hud"
description="Your Mac has not been restarted within 14 days. Once complete, you will be prompted to restart immediately.

Restarting your Mac frequently helps with performance, bugs and glitches. We advise that you restart now, close and save all your open files and click 'Restart.''

If you cannot restart now, you can come back to this window later."

button1="Restart"
icon="/tmp/lock_icon.png"
title="No Rest"
alignDescription="right" 
alignHeading="center"
defaultButton="1"

# JAMF Helper window as it appears for targeted computers
userChoice=$("$jamfHelper" -windowType "$windowType" -lockHUD -title "$title" -defaultButton "$defaultButton" -icon "$icon" -description "$description" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -button1 "$button1")

# If user selects "Restart"
if [ "$userChoice" == "0" ]; then
   echo "User clicked Restart; rebooting immediately.."
   # Send restart command
   shutdown -r now
	exit 0    
fi