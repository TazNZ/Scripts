#!/bin/bash

# Install Rosetta for Apple Silicon
arch=$(/usr/bin/arch)
if [ "$arch" == "arm64" ]; then
    echo "Installing Rosetta for Apple Silicon"
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    exit 0
elif [ "$arch" == "i386" ]; then
    echo "Intel detected - Skipping Rosetta"
    exit 0
else
    echo "ERROR - Unknown Processor detected"
    exit 1
fi