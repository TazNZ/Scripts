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
echo "Status: Downloading Xerox Drivers" >> $DNLOG
$JAMF policy -event "Install Fuji Xerox Drivers"
echo "Status: Downloading FindMe Printers" >> $DNLOG
$JAMF policy -event "Install FindMe Printers"


# Download and Install Brother Printer Drivers
echo "Status: Downloading Brother Printer Drivers" >> $DNLOG
if [ ! -f /Library/Printers/PPDs/Contents/Resources/Brother\ HL-2250DN\ series\ CUPS.gz ]; then
$JAMF policy -event "Install Brother Printer Drivers"
else
echo "Status: Brother Printer Drivers already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install PaperCut
echo "Status: Downloading PaperCut Client" >> $DNLOG
if [ ! -d $APP/PCClient.app ]; then
$JAMF policy -event "Install PaperCut Client"
else
echo "Status: PaperCut Client already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install Google Chrome
echo "Status: Downloading Google Chrome" >> $DNLOG
if [ ! -d $APP/Google\ Chrome.app ]; then
$JAMF policy -event "AutoUpdate-Google Chrome"
else
echo "Status: Google Chrome already installed... Skipping" >> $DNLOG
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

# Download and Install Microsoft Office 2019 VL Serialiser
echo "Status: Downloading Microsoft Office 2019 VL Serialiser" >> $DNLOG
$JAMF policy -event "Install Microsoft Office VL Serialiser License"
sleep 3

# Download and Install VLC
echo "Status: Downloading VLC" >> $DNLOG
if [ ! -d $APP/VLC.app ]; then
$JAMF policy -event "AutoUpdate-VLC"
else
echo "Status: VLC already installed... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install beQUIET
echo "Status: Downloading beQUIET" >> $DNLOG
if [ ! -d $APP/beQUIET.app ]; then
$JAMF policy -event "Install beQUIET"
else
echo "Status: beQUIET already installed... Skipping" >> $DNLOG
sleep 3
fi


# Configuring Remote access
echo "Status:  Enabling Screen Sharing" >> $DNLOG
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -access -on -users magsadmin -privs -all -activate

# Set Firmware Password
echo "Status: Setting Firmware Lock" >> $DNLOG
result=`/usr/sbin/firmwarepasswd -check`
if [[ "$result" == "Password Enabled: No" ]]; then
$JAMF policy -event "Firmware Password"
else
echo "Status: Firmware Lock already set... Skipping" >> $DNLOG
sleep 3
fi

# Download and Install MAGS Wallpapers
echo "Status: Downloading MAGS Wallpapers" >> $DNLOG
$JAMF policy -event "Install MAGS Wallpapers"
sleep 2

# Run scripts
echo "Status: Running Lab Scripts" >> $DNLOG
$JAMF policy -event "Enable AirPort Admin"
sleep 2

#############################################################################
# Add any additional triggers for apps that are added to new computers

# Trigger 1
arch=$(/usr/bin/arch)
if [ "$arch" == "arm64" ]; then
	echo "Status: Downloading Adobe Creative Cloud for Apple Silicon" >> $DNLOG
	$JAMF policy -event "AutoUpdate-Adobe Creative Cloud (M1)"
else
    echo "Status: Downloading Adobe Creative Cloud for Apple Intel" >> $DNLOG
    $JAMF policy -event "AutoUpdate-Adobe Creative Cloud (Intel)"
fi

# Trigger 2
echo "Status: Downloading Minecraft for Education" >> $DNLOG
if [ ! -d $APP/minecraftpe.app ]; then
$JAMF policy -event "Install Latest Minecraft for Education"
else
echo "Status: Minecraft for Education already installed..." >> $DNLOG
fi

# Trigger 3
echo "Status: Sibelius Ultimate" >> $DNLOG
if [ ! -d $APP/Sibelius.app ]; then
$JAMF policy -event "Install Sibelius Ultimate"
else
echo "Status: Sibelius Ultimate already installed..." >> $DNLOG
fi

# Trigger 4
echo "Status: AutoDesk Fusion 360" >> $DNLOG
if [ ! -d $APP/Autodesk\ Fusion\ 360.app ]; then
$JAMF policy -event "Install AutoDesk Fusion 360"
else
echo "Status: AutoDesk Fusion 360 already installed..." >> $DNLOG
fi

# Finish and completed
echo "Command: MainText: This Mac is now finished and ready to go! \n \n This Mac will now restart in 1 minute to complete the last few updates." >> $DNLOG
echo "Status: Enrollment Completed!" >> $DNLOG
sleep 5

# Finish caffeine
kill "$caffeinatepid"

# Return NoMADLoginAD to normal
/usr/local/bin/authchanger -reset -AD
sleep 2
sudo killall loginwindow

exit 0