#!/bin/bash

# Clears KAMAR caches and resolves startup issues.

# Kill KAMAR if open
killall "FileMaker Pro"
killall "FileMaker Pro Advanced"

# Clear FileMaker Caches
rm -rf ~/Library/Caches/FileMaker/*

exit 0