#!/bin/bash

# Variables
loggedInUser=$(stat -f%Su /dev/console)
computerName=$(scutil --get ComputerName)
jamf=/usr/local/bin/jamf
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
windowType="fs"
description="Hi, $computerName, to be able to use your Laptop you will need to read and agree to the New TELA Device Agreement for Teachers.

You can find the full TELA Device Agreement inside your Laptop bag. Please read it before continuing. You can also find the Agreement on the MAGS website, under Staff Portal.
Clicking Agree, also confirms that this device and it's serial number is registerted under your name.

If you require assistance or are unsure of this procedure, please contact the Helpdesk by email at helpdesk@mags.school.nz or phone 8160"

button1="AGREE"
button2="disagree"
title="TELA+ Device Agreement - Welcome to Mount Albert Grammar School"
alignDescription="left" 
alignHeading="center"
defaultButton="1"

#---------------------------------------------------------------------------------------------

if [ ! -f "/Users/Shared/Agreement/AGREED.plist" ] ; then
userChoice=$("$jamfHelper" -windowType "$windowType" -lockHUD -title "$title" -defaultButton "$defaultButton" -icon "$icon" -description "$description" -alignDescription "$alignDescription" -alignHeading "$alignHeading" -button1 "$button1" -button2 "$button2")
    if [ "$userChoice" == "0" ]; then
        echo "User clicked AGREE, sent confirmation to Jamf Cloud that $loggedInUser agreed."
        mkdir /Users/Shared/Agreement
        touch /Users/Shared/Agreement/AGREED.plist
		$jamf recon
    elif [ "$userChoice" == "2" ]; then
        echo "User clicked DISAGREE. Computer will log out"
        /usr/bin/sudo /usr/bin/killall loginwindow
        exit 0
    fi
else
	echo "User has already agreed to the device agreement."
    exit 0
fi