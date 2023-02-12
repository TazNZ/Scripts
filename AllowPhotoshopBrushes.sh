#!/bin/bash

# Author:   TazNZ - Jordan Noovao
# Name:     AllowPhotoshopBrushes.sh
#
# Purpose:  This script adds the 777 permissions to the Photoshop applications folder, to help assist with 
# standard users installing or editing their own Photoshop brushes.
# Tested within Jamf Pro and Microsoft Intune.
#
# With Jamf Pro - Add the version year as parameter 4.

# Update: Adobe Creative Cloud may have resolve this in recent versions...

# Variables
VersionYear=$4

chmod 777 "/Applications/Adobe Photoshop $VersionYear/Presets"

exit 0
