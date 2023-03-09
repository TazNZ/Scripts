#!/bin/bash

# Clear all apps from dock and touch file to report back to MDM for Dock config profile.

# Logged in user
consoleuser=ls -l /dev/console | cut -d " " -f4

# Clear all dock items
su - "${consoleuser}" -c 'defaults write com.apple.dock persistent-apps -array'

# Touch file for EA
touch /var/tmp/dock_cleared.txt