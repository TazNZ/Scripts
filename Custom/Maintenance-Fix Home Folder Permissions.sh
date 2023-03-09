#/bin/bash

# Fix the "Grant Access Issue" from Microsoft Office apps when trying to open anything belonging to the poor user.

# Set Home Folder to 755
chmod 755 ~/*
sleep 2

# run diskutil user permissions fix
diskutil resetUserPermissions / `id -u`
echo "Disk Utility has finished, restarting now"
sleep 2

shutdown -r now

# Hopefully this resolves the issue, when the Mac reboots try to open any of the files that couldnt open before.