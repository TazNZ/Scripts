#! /bin/sh

#Determine current logged in user
User="$(who|awk '/console/ {print $1}')"

# Clear PaperCut
if [ -f /Library/LaunchAgents/com.papercut.client.agent.plist ]; then
    sudo -u "$User" /bin/launchctl unload $3/Library/LaunchAgents/com.papercut.client.agent.plist
fi
sleep 2
killall "JavaAppLauncher"

# Remove previous version
rm -rf /Applications/PCClient.app

exit 0