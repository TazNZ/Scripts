#!/bin/bash
# Created by Jordan @ImageText NZ
# 17-02-2022

#########################################################################################
# Policy Variables to Modify
#########################################################################################

# The policy array must be formatted "Progress Bar text,trigger". These will be
# run in order as they appear below.
  POLICY_ARRAY=(
    "Installing Crowdstrike,crowdstrike"
    "Installing Forticlient,forticlient"
    "Installing Microsoft Excel 365,excel"
    "Installing Microsoft Outlook 365,outlook"
    "Installing Microsoft PowerPoint 365,powerpoint"
    "Installing Microsoft Teams 365,teams"
    "Installing Microsoft Word 365,word"
    "Installing Google Chrome,googlechrome"
  )
  
# Main ImageFile - Path to icon
iconFile="/System/Library/CoreServices/Install in Progress.app/Contents/Resources/Installer.icns"

# Last screen ImageFile
finaliconFile="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.macbookpro-15-retina-touchid-silver.icns"

# Organisation Name
Org="Auckland Transport"


#########################################################################################
# Policy Variables to NOT modify
#########################################################################################

# Log file for Notify to read
NOTIFY_LOG="/var/tmp/depnotify.log"
JAMF_BINARY="/usr/local/jamf/bin/jamf"


#########################################################################################
# Main Notify Script - Don't modify or else!
#########################################################################################

# Install Rosetta
arch=$(/usr/bin/arch)
if [ "$arch" == "arm64" ]; then
    echo "Apple Silicon - Installing Rosetta"
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
else
    echo "Intel - Skipping Rosetta"
fi

# Download and Install NoMADLoginAD
if [ ! -f /usr/local/bin/authchanger ]; then
$JAMF_BINARY policy -id "27"
else
echo "NoMADLoginAd already installed" >> $NOTIFY_LOG
sleep 3
fi

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
	 
# Start NoMADLoginAD Notify (1.4.0)
/usr/local/bin/authchanger -reset -AD -prelogin NoMADLoginAD:Notify
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
 
# Clean Up and re
/usr/local/bin/authchanger -reset -AD	
/bin/echo "Command: RestartNow:" >> $NOTIFY_LOG
rm -rf $NOTIFY_LOG