#!/bin/bash

# Author:   TazNZ - Jordan Noovao
# Name:     JamfConnect-Notify.sh
#
# Purpose:  This script utilises the Notify feature in Jamf Connect.
# The "Policy Variables to Modify" is the only section that will need to be modified to 
# your specific Jamf Policies and triggers.
# Visit https://gitlab.com/Mactroll/DEPNotify for more info on how the policies and triggers 
# work within this script.

# Currently tested in Jamf Connect 2.9.0 

#########################################################################################
# Policy Variables to Modify
#########################################################################################

# The policy array must be formatted "Progress Bar text,trigger". These will be
# run in order as they appear below.
  POLICY_ARRAY=(
"Installing Google Chrome,chrome"
"Installing Nudge,nudge"
"Installing Microsoft Office 365,office365"
"Checking for Apple Software updates,appleupdates"
  )
  
# Main ImageFile - Path to icon
iconFile="/System/Library/CoreServices/Install in Progress.app/Contents/Resources/Installer.icns"

# Last screen ImageFile
finaliconFile="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.macbookpro-15-retina-touchid-silver.icns"

# Organisation Name
Org="ThePretendCompany"


#########################################################################################
# Policy Variables to NOT modify
#########################################################################################

# Log file for Notify to read
NOTIFY_LOG="/var/tmp/depnotify.log"
JAMF_BINARY="/usr/local/jamf/bin/jamf"


#########################################################################################
# Main Notify Script - Don't modify or else!
#########################################################################################

# Pump me with Starbucks
/usr/bin/caffeinate -d -i -m -s -u &
caffeinatepid=$!

# Clear any existing Notify Logs
rm $NOTIFY_LOG

# Preset Notify file for first launch
/bin/echo "Command: Image: $iconFile" >> $NOTIFY_LOG
/bin/echo "Command: MainTitle: Welcome to $Org"  >> $NOTIFY_LOG
/bin/echo "Command: MainText: Your Mac is just downloading all the required infomation to start... This process can take about 15-20 mins, this timeframe does depend on your current internet connection speed and which applications and updates are required." >> $NOTIFY_LOG
/bin/echo "Status: Please wait..." >> $NOTIFY_LOG

# Wait for Setup Assistant to finish
SetupAssistance_process=$(/bin/ps auxww | grep -q "[S]etup Assistant.app")
while [ $? -eq 0 ]
do
    /bin/echo "Setup Assistant Still Running... Sleep for 2 seconds..."
    /bin/sleep 2
    SetupAssistance_process=$(/bin/ps auxww | grep -q "[S]etup Assistant.app")
done
	 
# Start Jamf Connect Notify (2.9.0)
/usr/local/bin/authchanger -reset -JamfConnect -prelogin JamfConnectLogin:Notify
/bin/sleep 2
sudo /usr/bin/killall -9 loginwindow # sudo required to kill login window
/bin/sleep 60

# Checking policy array and adding the count from the additional options above.
ARRAY_LENGTH="$((${#POLICY_ARRAY[@]}+ADDITIONAL_OPTIONS_COUNTER))"
/bin/echo "Command: Determinate: $ARRAY_LENGTH" >> $NOTIFY_LOG

# Loop to run policies
for POLICY in "${POLICY_ARRAY[@]}"; do
/bin/echo "Status: $(echo "$POLICY" | cut -d ',' -f1)" >> $NOTIFY_LOG
$JAMF_BINARY policy -event "$(echo "$POLICY" | cut -d ',' -f2)"
done
 
# Finishing up
/bin/echo "Command: Image: $finaliconFile" >> $NOTIFY_LOG
/bin/echo "Command: MainText: Your Mac has finished installing all required apps! Your Mac will now restart to complete any updates. If there any  updates due. The Restart process will take a bit longer." >> $NOTIFY_LOG
/bin/echo "Status: Finishing up... Your Mac is almost ready!" >> $NOTIFY_LOG
/bin/sleep 20
 
# Clean Up
/usr/local/bin/authchanger -reset -JamfConnect	
/bin/echo "Command: Quit:" >> $NOTIFY_LOG
/bin/sleep 1
rm -rf $NOTIFY_LOG

# Restart macOS
sudo shutdown -r now # sudo required to force shutdown
