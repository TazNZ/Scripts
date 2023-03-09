#!/bin/bash
#
# DEPNotify Script - Faculty
#
# Purpose: Install and run DEPNotify at enrollment time and do some final touches
# for the Mac.  It also checks for software updates and installs them if found.
#
# Setting the parameters
JAMF=$(/usr/bin/which jamf)
CURRENTUSER=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
APP=$(/Applications/)
DNLOG=/var/tmp/depnotify.log

# Caffeine this Mac because it needs to stay awake during this process
/usr/bin/caffeinate -d -i -m -u &
caffeinatepid=$!

# Create new Log file for DEPNotify
rm -rf $DNLOG
touch $DNLOG

# Install DEPNotify
$JAMF policy -event "Install DEPNotify"
sleep 5

# Wait for desktop and dock
dockStatus=$(pgrep -x Dock)
log "Waiting for Desktop"
while [ "$dockStatus" == "" ]; do
  log "Desktop is not loaded. Waiting."
  sleep 2
  dockStatus=$(pgrep -x Dock)
done

# Start DEPNotify
echo "Status: Preparing Enrollment..." >> $DNLOG
sleep 3
sudo -u "$CURRENTUSER" /Applications/Utilities/DEPNotify.app/Contents/MacOS/DEPNotify -jamf &
sleep 5

# Prepare enrollment
echo "Command: MainTitle: Welcome to Mount Albert Grammar School" >> $DNLOG
echo "Command: MainText: This Mac is now finding and installing the apps and settings it needs.  \n \n Do not shut down, restart, close or unplug this Mac until the process is complete." >> $DNLOG
echo "Status: Preparing Enrollment..." >> $DNLOG
echo "Command: Determinate: 50" >> $DNLOG
sleep 10

# Set name of device
echo "Status: Setting name of device..." >> $DNLOG
$JAMF policy -event "Rename Computer"
sleep 3

# Install Rosetta for Apple Silicon
arch=$(/usr/bin/arch)
if [ "$arch" == "arm64" ]; then
    echo "Installing Rosetta for Apple Silicon" >> $DNLOG
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
elif [ "$arch" == "i386" ]; then
    echo "Intel detected - Skipping Rosetta" >> $DNLOG
else
    echo "ERROR - Unknown Processor detected - DEPNotify will crash" >> $DNLOG
    exit 1
fi

# Download Apple Software Updates
echo "Status: Checking for Apple Software Updates" >> $DNLOG
/usr/sbin/softwareupdate --background

# Download and Install NoMAD Client
echo "Status: Downloading NoMAD" >> $DNLOG
if [ ! -d $APP/NoMAD.app ]; then
$JAMF policy -event "AutoUpdate-NoMAD"
$JAMF policy -event "Install NoMAD LaunchAgent"
else
echo "Status: NoMAD already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install FindMe Printers
echo "Status: Downloading FindMe Printers" >> $DNLOG
$JAMF policy -event "Install FindMe Printers"

# Download and Install PaperCut
echo "Status: Downloading PaperCut" >> $DNLOG
if [ ! -d $APP/PCClient.app ]; then
$JAMF policy -event "Install PaperCut Client"
else
echo "Status: PaperCut Client already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install Microsoft Word
echo "Status: Downloading Microsoft Word" >> $DNLOG
if [ ! -d $APP/Microsoft\ Word.app ]; then
$JAMF policy -event "AutoUpdate-Microsoft Word"
else
echo "Status: Microsoft Word already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install Microsoft Excel
echo "Status: Downloading Microsoft Excel" >> $DNLOG
if [ ! -d $APP/Microsoft\ Excel.app ]; then
$JAMF policy -event "AutoUpdate-Microsoft Excel"
else
echo "Status: Microsoft Excel already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install Microsoft PowerPoint
echo "Status: Downloading Microsoft PowerPoint" >> $DNLOG
if [ ! -d $APP/Microsoft\ PowerPoint.app ]; then
$JAMF policy -event "AutoUpdate-Microsoft PowerPoint"
else
echo "Status: Microsoft PowerPoint already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install Microsoft Outlook
echo "Status: Downloading Microsoft Outlook" >> $DNLOG
if [ ! -d $APP/Microsoft\ Outlook.app ]; then
$JAMF policy -event "AutoUpdate-Microsoft Outlook"
else
echo "Status: Microsoft Outlook already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install Microsoft OneNote
echo "Status: Downloading Microsoft OneNote" >> $DNLOG
if [ ! -d $APP/Microsoft\ OneNote.app ]; then
$JAMF policy -event "AutoUpdate-Microsoft OneNote"
else
echo "Status: Microsoft OneNote already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install F5Access VPN
echo "Status: Downloading F5Access VPN" >> $DNLOG
if [ ! -f /Library/LaunchAgents/com.f5.access.macos.plist ]; then
$JAMF policy -event "Install F5Access LaunchAgent"
else
echo "Status: F5Access VPN already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install VLC
echo "Status: Downloading VLC" >> $DNLOG
if [ ! -d $APP/VLC.app ]; then
$JAMF policy -event "AutoUpdate-VLC"
else
echo "Status: VLC already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install KAMAR Opener
echo "Status: Downloading KAMAR Opener" >> $DNLOG
if [ ! -f /Users/Shared/KAMAR.fmp12 ]; then
$JAMF policy -event "Install KAMAR Opener"
else
echo "Status: KAMAR Opener already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install FileMaker Pro
echo "Status: Downloading FileMaker Pro" >> $DNLOG
if [ ! -d $APP/FileMaker\ Pro.app ]; then
$JAMF policy -event "Install FileMaker Pro"
else
echo "Status: FileMaker Pro already installed... Skipping" >> $DNLOG
sleep 3
fi

# Configuring Remote access
echo "Status:  Enabling Screen Sharing" >> $DNLOG
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -access -on -users magsadmin -privs -all -activate

# Install Apple Software Updates
echo "Status:  Installing Apple Software Updates" >> $DNLOG
/usr/sbin/softwareupdate --install --all --force --agree-to-license

# Run Jamf Recon to check for VPP apps
echo "Status: Checking Jamf for last bits" >> $DNLOG
$JAMF recon
echo "Status: Updating Asset list" >> $DNLOG
$JAMF policy -event "Update Inventory"

# Finish caffeine
kill "$caffeinatepid"

# Finish and completed
echo "Command: MainText: This Mac is now finished and ready to go! \n \n This Mac will now restart in 1 minute to complete the last few updates." >> $DNLOG
echo "Status: Enrollment Completed!" >> $DNLOG
sleep 60
echo "Command: RestartNow:" >> $DNLOG

# Remove DEPNotify and the logs
rm -Rf $DNLOG

exit 0