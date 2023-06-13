#!/bin/bash

# Author:   TazNZ - Jordan Noovao
# Name:     BrewInstallAssistant.sh
#
# Purpose:  This script assists users (mainly devs) in installing Homebrew packages.
# It is designed to be used as a Self Service option in Jamf Pro.  
#
# This version of Brew Install Assistant is Static, meaning that the user can only install the Brew formulaes or apps, allowed. 
# Check line 18
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Brew Applications and Packages
# This script does not currently support cask items
# Use https://formulae.brew.sh/ as a reference to find the correct package name.
brewApps="autoconf,bdw-gc,brotli,c-ares,ca-certificates,docker,docker-compose,gdbm,gettext,glib,gmp,gnutls,go,guile,icu4c,jpeg,jq,libevent,libffi,libidn2,libnghttp2,libpng,libslirp,libssh,libtasn1,libtool,libunistring,libusb,libuv,lima,lzo,m4,maven,mpdecimal,ncurses,nettle,node,oniguruma,openjdk,openssl@1.1,p11-kit,pcre,pixman,pkg-config,pyenv,pyenv-virtualenvwrapper,python@3.8,python@3.9,qemu,readline,snappy,sqlite,tcl-tk,unbound,vde,xz,zlib,zstd"

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
	echo "${package} is installed already. Skipping installation"
else
	echo "Searching for ${package}. Attempting installation..."
	sudo -H -iu ${ConsoleUser} ${brew} install ${package}
fi
exit 0
