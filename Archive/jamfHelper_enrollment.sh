#!/bin/bash

#################################################################################
# This script was created with love and compassion. ❤️
# Slack - MacAdmins user: taz
# December 2021
#################################################################################

# Variables

# Set these for your environment
jamfHelperHeading='Mount Albert Grammar School'
jamfHelperIconPath='/tmp/icon'
launchAgentName='nz.school.mags.jamfHelperSplashScreen'
jamfBinary=$(/usr/bin/which jamf)

# You probably don't need to change these
launchAgentPath="/Library/LaunchAgents/${launchAgentName}.plist"
jamfHelperPath='/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper'

# Functions

startSplashScreen () {

# Check for user not logged in
if [[ -z "$loggedInUser" ]]; then
  
  # Remove existing LaunchAgent
  if [[ -f ${launchAgentPath} ]]; then
    rm ${launchAgentPath}
  fi

  # Write LaunchAgent to load jamfHelper script
  defaults write ${launchAgentPath} KeepAlive -bool true
  defaults write ${launchAgentPath} Label ${launchAgentName}
  defaults write ${launchAgentPath} LimitLoadToSessionType "LoginWindow"
  defaults write ${launchAgentPath} ProgramArguments -array-add "$jamfHelperPath"
  defaults write ${launchAgentPath} ProgramArguments -array-add "-windowType"
  defaults write ${launchAgentPath} ProgramArguments -array-add "fs"
  defaults write ${launchAgentPath} ProgramArguments -array-add "-heading"
  defaults write ${launchAgentPath} ProgramArguments -array-add "$jamfHelperHeading"
  defaults write ${launchAgentPath} ProgramArguments -array-add "-description"
  defaults write ${launchAgentPath} ProgramArguments -array-add "$message"
  defaults write ${launchAgentPath} ProgramArguments -array-add "-icon"
  defaults write ${launchAgentPath} ProgramArguments -array-add "$jamfHelperIconPath"
  defaults write ${launchAgentPath} RunAtLoad -bool true 
  chown root:wheel ${launchAgentPath}
  chmod 644 ${launchAgentPath}
  echo "Created Launch Agent to run jamfHelper"
  
  # Kill/restart the loginwindow process to load the LaunchAgent
  echo "Ready to lock screen. Restarting loginwindow..."
  if [[ ${osversMajor} -eq 10 && ${osversMinor} -le 14 ]]; then
    killall -HUP loginwindow
  fi
  if [[ ${osversMajor} -eq 10 && ${osversMinor} -ge 15 ]]; then
    launchctl kickstart -k system/com.apple.loginwindow # kickstarting the login window works but is slower and results in a runaway SecurityAgent process in macOS 10.15
    sleep 0.5
    killall -HUP SecurityAgent # kill the runaway SecurityAgent process
  fi
  if [[ ${osversMajor} -ge 11 ]]; then
    launchctl kickstart -k system/com.apple.loginwindow
  fi
fi
}

killSplashScreen () {
# Remove existing LaunchAgent and restart login window
if [[ -f ${launchAgentPath} ]]; then
  echo "Removing LaunchAgent located at ${launchAgentPath}"
  rm ${launchAgentPath}
fi

echo "Restarting loginwindow..."
killall loginwindow
}

removeLaunchAgentAtReboot () {
# Create a self-destructing LaunchDaemon to remove our LaunchAgent at next startup
if [[ -f ${launchAgentPath} ]]; then
  launchDaemonName="${launchAgentName}.remove"
  launchDaemonPath="/Library/LaunchDaemons/${launchDaemonName}.plist"
  defaults write ${launchDaemonPath} Label "${launchDaemonName}"
  defaults write ${launchDaemonPath} ProgramArguments -array-add "rm"
  defaults write ${launchDaemonPath} ProgramArguments -array-add "${launchAgentPath}"
  defaults write ${launchDaemonPath} ProgramArguments -array-add "${launchDaemonPath}"
  defaults write ${launchDaemonPath} RunAtLoad -bool true
  chown root:wheel ${launchDaemonPath}
  chmod 644 ${launchDaemonPath}
  echo "Created Launch Daemon to remove ${launchAgentPath}"
fi
}

# Start script

osversMajor=$(sw_vers -productVersion | awk -F. '{print $1}')
osversMinor=$(sw_vers -productVersion | awk -F. '{print $2}')

# Only proceed if macOS version is 10.13 or higer
if [[ ${osversMajor} -eq 10 && ${osversMinor} -le 12 ]]; then
  echo "macOS version ${osversMajor}.${osversMinor} not supported."
  exit 0
fi

# Get currently logged in user
loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Wait for _mbsetupuser to not be logged in (used by Apple for setup screens)
while [[ $loggedInUser = "_mbsetupuser" ]]
do
  sleep 5
  loggedInUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
  #echo "Waiting for _mbsetupuser"
done

# Check for logged in user and exit if true
if [[ -n "$loggedInUser" ]]; then
  echo "$loggedInUser is logged in. Exiting..."
  exit 0
fi

message="Starting Setup..."
startSplashScreen
sleep 5

# Keep this Mac from dozing off
/usr/bin/caffeinate -d -i -m -u &
caffeinatepid=$!

# Prevent Jamf check-in policies from running until next reboot
launchctl unload /Library/LaunchDaemons/com.jamfsoftware.task.1.plist
launchctl unload /Library/LaunchDaemons/com.jamfsoftware.jamf.daemon.plist

# Run Jamf enrollment policies (custom these as needed for your environment)
# When you want to change the jamfHeper message, set the message variable and run startSplashScreen
# Either run killSplashScreen at the end of your script or use removeLaunchAgentAtReboot if you will be restarting the computer
# Install Rosetta for Apple M1
arch=$(/usr/bin/arch)
if [ "$arch" == "arm64" ]; then
    message="Installing Rosetta..."
    startSplashScreen
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
elif [ "$arch" == "i386" ]; then
    message="Intel detected - Skipping Rosetta"
    startSplashScreen
else
    message="ERROR - Unknown Processor detected - jamfHelper will quit"
    startSplashScreen
    exit 1
fi


# Set computer name
message="Setting device name..."
startSplashScreen
jamf policy -event "Rename Computer"

# Enable Screen Sharing
message="Turning on Screen Sharing..."
startSplashScreen
$jamfBinary policy -event "Enable Screen Sharing"

# Install NoMAD
message="Installing NoMAD..."
startSplashScreen
$jamfBinary policy -event "AutoUpdate-NoMAD"
$jamfBinary policy -event "Install NoMAD LaunchAgent"

# Install Printers
message="Installing Xerox Photocopiers..."
startSplashScreen
$jamfBinary policy -event "Install FindMe Printers"

# Install PaperCut
message="Installing PaperCut..."
startSplashScreen
$jamfBinary policy -event "Install PaperCut Client"

# Install Microsoft Word
message="Installing Microsoft Word..."
startSplashScreen
$jamfBinary policy -event "AutoUpdate-Microsoft Word"

# Install Microsoft Excel
message="Installing Microsoft Excel..."
startSplashScreen
$jamfBinary policy -event "AutoUpdate-Microsoft Excel"

# Install Microsoft PowerPoint
message="Installing Microsoft PowerPoint..."
startSplashScreen
$jamfBinary policy -event "AutoUpdate-Microsoft PowerPoint"

# Install Microsoft Outlook
message="Installing Microsoft Outlook..."
startSplashScreen
$jamfBinary policy -event "AutoUpdate-Microsoft Outlook"

# Install Microsoft OneNote
message="Installing Microsoft OneNote..."
startSplashScreen
$jamfBinary policy -event "AutoUpdate-Microsoft OneNote"

# Install F5 Access VPN
message="Installing F5 Access..."
startSplashScreen
$jamfBinary policy -event "Install F5Access LaunchAgent"

# Install VLC
message="Installing VLC Player..."
startSplashScreen
$jamfBinary policy -event "AutoUpdate-VLC"

# Install KAMAR
message="Installing KAMAR..."
startSplashScreen
$jamfBinary policy -event "Install KAMAR Opener"

# Install FileMaker
message="Installing FileMaker..."
startSplashScreen
$jamfBinary policy -event "Install FileMaker Pro"

# Update inventory to avoid running unneccessary startup policies
message="Updating Inventory..."
startSplashScreen
$jamfBinary recon

# Run Jamf startup policies
message="Checking Policies..."
startSplashScreen
$jamfBinary policy -event startup

# Cleanup (anything you might want to do before starting software updates and/or restarting the computer)
removeLaunchAgentAtReboot

# Check for software updates and restart to complete setup
message="Checking for Apple Software Updates..."
startSplashScreen
/usr/sbin/softwareupdate --install --all --force --agree-to-license --restart
kill "$caffeinatepid"
reboot