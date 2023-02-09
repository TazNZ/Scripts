#!/bin/bash

# Author:   TazNZ - Jordan Noovao
# Name:     allowEveryonelpadminAdminRights.sh
#
# Purpose:  This script enables all local users admin access to Printers using the lpadmin group in macOS.
# This is designed to be used within Jamf Pro but it has been successfully tested using Microsoft Intune too. Just comment out lines 14 - 18

writelog ()
{
    # Write to system log
    /usr/bin/logger -is -t "${LOG_PROCESS}" "${1}"
    
    # Check for Jamf log, and write to it if it exists
    if [ -e "/var/log/jamf.log" ] &amp;&amp; [ "$(whoami)" == "root" ]
    then
        /bin/echo "$(date +"%a %b %d %T") $(/usr/sbin/scutil --get ComputerName | awk -F "." '{ print $1 }') jamf[${LOG_PROCESS}]: ${1}" &gt;&gt; "/var/log/jamf.log"
    fi
}

# This function outputs all variables set above to stdout and logger, as defined in the writelog function above

echoVariables ()
{
    writelog "Log Process is ${LOG_PROCESS}"
}

##### Set variables

LOG_PROCESS="allowEveryonePrintAdminRights"

##### Run script

echoVariables

writelog "Adding UNIX group \"everyone\" to UNIX group \"_lpadmin\"..."

/usr/sbin/dseditgroup -o edit -t group -a everyone _lpadmin

if [ $? != 0 ]
then
    writelog "Unable to add UNIX group \"everyone\" to UNIX group \"_lpadmin\". Bailing..."
    exit 1
else
    writelog "Added UNIX group \"everyone\" to UNIX group \"_lpadmin\" successfully!"
fi

writelog "Script completed."