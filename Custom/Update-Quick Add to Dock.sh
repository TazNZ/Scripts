#!/bin/bash

defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$4</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'

killall Dock