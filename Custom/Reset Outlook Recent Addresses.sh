#!/bin/bash

loggedInUser=$(stat -f%Su /dev/console)

/usr/bin/osascript << EOF
set userName to do shell script "echo \"$loggedInUser\""

using terms from application "Microsoft Outlook"
	tell application "Microsoft Outlook"
		clear recent recipients
	end tell
end using terms from

EOF