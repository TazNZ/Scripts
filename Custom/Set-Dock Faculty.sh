#!/bin/bash

echo "running dockutil"
DOCKUTIL=/usr/local/bin/dockutil
loggedInUser=$(python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')

echo "remove default apps"
# remove default apps 
$DOCKUTIL --remove all --no-restart --allhomes
echo "adding to dock"
# add items to dock
$DOCKUTIL --add /System/Applications/Launchpad.app --position 1 --no-restart --allhomes
$DOCKUTIL --add /System/Applications/Siri.app --after Launchpad --no-restart --allhomes
$DOCKUTIL --add /Applications/Self\ Service.app --after Siri --no-restart --allhomes
$DOCKUTIL --add /Applications/Safari.app --after "Self Service" --no-restart --allhomes
$DOCKUTIL --add /Applications/Microsoft\ Outlook.app --after Safari --no-restart --allhomes
$DOCKUTIL --add /Applications/Microsoft\ Word.app --after "Microsoft Outlook" --no-restart --allhomes
$DOCKUTIL --add /Applications/Microsoft\ Excel.app --after "Microsoft Word" --no-restart --allhomes
$DOCKUTIL --add /Applications/Microsoft\ PowerPoint.app --after "Microsoft Excel" --no-restart --allhomes
$DOCKUTIL --add /Applications/Microsoft\ Word.app --after "Microsoft Outlook" --no-restart --allhomes

$DOCKUTIL --add '~/Downloads' --view grid --display folder --sort name  --section others --position 1 --allhomes

exit 0