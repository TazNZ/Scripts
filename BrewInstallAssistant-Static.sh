#!/bin/bash

# Author:   TazNZ - Jordan Noovao
# Name:     BrewInstallAssistant.sh
#
# Purpose:  This script assists users (mainly devs) in installing Homebrew packages.
# It is designed to be used as a Self Service option in Jamf Pro.  
#
#
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Brew Applications and Packages
# This script does not currently support cask items
# Use https://formulae.brew.sh/ as a reference to find the correct package name. Add each package you want to include and comma between.
brewApps="autoconf,bdw-gc,brotli,c-ares,ca-certificates,docker,docker-compose,gdbm,gettext,glib,gmp,gnutls,go,guile,icu4c,jpeg,jq,libevent,libffi,libidn2,libnghttp2,libpng,"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Dialog Title, Message and Icon

title="Brew Install Assistant "
message="Please select the Homebrew package you wish to install from the dropdown. All brew packages in this list are all approved and ready to install."
icon="https://brew.sh/assets/img/homebrew.svg"

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
--selecttitle \"Select a Brew Package\" \
--selectvalues \"$brewApps\" \
--position 'centre' \
--moveable \
--quitkey x"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Welcome Screen and capture user's interaction

userInput=$( eval "$dialogCMD" )
package=$( echo "$userInput" | grep "SelectedOption" | awk -F " : " '{print $NF}' | sed 's/"//g')
echo "Option: ${package}"

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
dialogCMD="$dialogApp --ontop --title \"No need for $package.\" \
--message \"You already have "$package" installed! Open Terminal.app and type $package to start using it.\" \
--icon \"$icon\" \
--infotext \"v1\" \
--titlefont 'size=32' \
--messagefont 'size=18' \
--position 'centre' \
--moveable \
--quitkey x"
eval "$dialogCMD"
    echo "${package} is installed already. Skipping installation"
else
dialogCMD="$dialogApp --ontop --title \"Installing $package.\" \
--message \"$package is on it's way to your Mac. Once downloaded and installed, you can run it using the developers recommneded methods.\" \
--icon \"$icon\" \
--infotext \"v1\" \
--titlefont 'size=32' \
--messagefont 'size=18' \
--position 'centre' \
--moveable \
--quitkey x"
eval "$dialogCMD"
	sudo -H -iu ${ConsoleUser} ${brew} install ${package}
    dialogCMD="$dialogApp --ontop --title \"Successfully installed $package.\" \
--message \"$package is ready! You can run it. Please refer to the developers guide or recommendations on how to run these packages. Click Ok to dismiss\" \
--icon \"$icon\" \
--infotext \"v1\" \
--titlefont 'size=32' \
--messagefont 'size=18' \
--position 'centre' \
--moveable \
--quitkey x"
eval "$dialogCMD"
fi