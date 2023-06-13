#!/bin/bash

# Author:   TazNZ - Jordan Noovao
# Name:     BrewInstallAssistant.sh
#
# Purpose:  This script assists users (mainly devs) in installing Homebrew packages.
# It is designed to be used as a Self Service option in Jamf Pro.  
#
# This version of Brew Install Assistant is Dynamic, meaning that the user can fill in any Brew formulaes or apps.  
# As long as it exists at https://formulae.brew.sh
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Dialog Title, Message and Icon

title="Brew Install Assistant "
message="Please type the Homebrew package you wish to install into the text field below. \n\nGo to https://formulae.brew.sh/ to find the name of the package you want to install. \n\nYou must enter the package name exactly from the Install comammnd e.g. $ brew install docker"
icon="https://brew.sh/assets/img/homebrew-256x256.png"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Dialog Settings and Features

dialogApp="/usr/local/bin/dialog"

dialogCMD="$dialogApp --ontop --title \"$title\" \
--message \"$message\" \
--icon \"$icon\" \
--button1text \"Install\" \
--button2 \
--infotext \"v1\" \
--titlefont 'size=32' \
--messagefont 'size=18' \
--textfield \"Brew Formulae\" \
--position 'centre' \
--moveable \
--quitkey x"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Download and install swiftDialog if it's not already installed 

if [ ! -f "$dialogApp" ]; then
    echo_logger "swiftDialog not installed"
    dialog_latest=$( curl -sL https://api.github.com/repos/bartreardon/swiftDialog/releases/latest )
    dialog_url=$(get_json_value "$dialog_latest" 'assets[0].browser_download_url')
    curl -L --output "dialog.pkg" --create-dirs --output-dir "/var/tmp" "$dialog_url"
    installer -pkg "/var/tmp/dialog.pkg" -target /
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Welcome Screen and capture user's interaction

package=$(eval "$dialogCMD" | awk -F " : " '{print $NF}')

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Start installing the selected Brew package
# Credit: Honestpuck https://github.com/Honestpuck

if [[ "$package" == "" ]]; then
echo "****  No package selected! exiting ****"
exit 1
fi

UNAME_MACHINE="$(uname -m)"

ConsoleUser=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Check if the item is already installed. If not, install it

if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    # M1/arm64 machines
    brew=/opt/homebrew/bin/brew
else
    # Intel/x86 machines
    brew=/usr/local/bin/brew
fi

cd /tmp/ # This is required to use sudo as another user or you get a getcwd error
if [[ $(sudo -H -iu ${ConsoleUser} ${brew} info ${package}) != *Not\ installed* ]]; then
	echo "${package} is installed already. Skipping installation"
else
	echo "Searching for ${package}. Attempting installation..."
	sudo -H -iu ${ConsoleUser} ${brew} install ${package}
fi
exit 0