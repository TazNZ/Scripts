#!/bin/sh
# Pre-Install_Script
# Uninstall old versions of FileMaker before installing the latest build.

# Kill KAMAR if open
killall "FileMaker Pro"
killall "FileMaker Pro Advanced"

# Clear FileMaker Caches
rm -rf ~/Library/Caches/FileMaker/*

# Remove all instances of FileMaker and configurations.
rm -Rf /Applications/FileMaker*
rm -Rf /Users/*/Library/Preferences/com.filemaker*
rm -Rf /Users/Shared/FileMaker*

exit 0