#!/bin/sh

# Creates a Launch Agent that Loads OneDrive at startup and will re-launch it every 15 minutes.
# OneDrive does not launch a second instance if run multiple times.

# Variables
ODBinary="/Applications/OneDrive.app/Contents/MacOS/OneDrive"
agentName="com.microsoft.OneDrive.agent"
agentPlist="/Library/LaunchAgents/$agentName.plist"

# Check for OneDrive Binary
if [[ -f "$ODBinary" ]]; then
# Echo plist into the launch agent folder
/bin/cat > "$agentPlist" << 'ONEDRIVE_LAUNCHAGENT'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.microsoft.OneDrive.agent</string>
	<key>LimitLoadToSessionType</key>
	<string>Aqua</string>
	<key>Program</key>
	<string>/Applications/OneDrive.app/Contents/MacOS/OneDrive</string>
	<key>RunAtLoad</key>
	<true/>
	<key>StartInterval</key>
	<integer>900</integer>
</dict>
</plist>
ONEDRIVE_LAUNCHAGENT

else 
	echo "OneDrive Binary was not detected, skipping launch agent."
	exit 1
fi

# Get Permissions Set
chown root:wheel "$agentPlist"
chmod 644 "$agentPlist"