﻿#!/bin/bash
#set -x

TOOL_NAME="Microsoft Office 365/2019/2016 Register AutoUpdate"
TOOL_VERSION="1.3"

## Copyright (c) 2018 Microsoft Corp. All rights reserved.
## Scripts are not supported under any Microsoft standard support program or service. The scripts are provided AS IS without warranty of any kind.
## Microsoft disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a 
## particular purpose. The entire risk arising out of the use or performance of the scripts and documentation remains with you. In no event shall
## Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever 
## (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary 
## loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility
## of such damages.
## Feedback: pbowden@microsoft.com

# Get the logged in user's user name - thanks to Erik Burglund - http://erikberglund.github.io/2018/Get-the-currently-logged-in-user,-in-Bash/
loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/[[:space:]]+Name[[:space:]]:/ { if ( $2 != "loginwindow" ) { print $2 }} ')

function ShowUsage {
# Shows tool usage and parameters
	echo $TOOL_NAME - $TOOL_VERSION
	echo "Purpose: Registers Microsoft AutoUpdate with the Operating System so that it auto-runs"
	echo "Usage: RegMAU [--Register]"
	echo "Example: RegMAU --Register"
	echo
	exit 0
}

# Evaluate command-line arguments
if [[ $# = 0 ]]; then
	ShowUsage
elif [ "$1" == "/" ]; then
		Register=true
else
	for KEY in "$@"
	do
	case $KEY in
    	--Help|-h|--help)
    	ShowUsage
    	shift # past argument
    	;;
    	--Register|-r|--register)
    	Register=true
    	shift # past argument
    	;;
		*)
    	ShowUsage
    	;;
    esac
	shift # past argument or value
	done
fi

## Main
if [ $Register ]; then
	if [ -d "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app" ]; then
		/usr/bin/sudo -u $loggedInUser /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f -trusted "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"
		/usr/bin/sudo -u $loggedInUser /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f -trusted "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/Microsoft Update Assistant.app"
		/usr/bin/sudo -u $loggedInUser defaults write com.microsoft.autoupdate2 StartDaemonOnAppLaunch -bool YES
		echo "Microsoft AutoUpdate registered successfully for user: ${loggedInUser}"
		echo
	fi
	else
		echo "Microsoft AutoUpdate not found"
		echo
		exit 1
fi

exit 0