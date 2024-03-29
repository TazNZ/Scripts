﻿#!/bin/sh
#set -x

TOOL_NAME="Microsoft Office for Mac Sign In Helper"
TOOL_VERSION="1.2.1"

## Copyright (c) 2018 Microsoft Corp. All rights reserved.
## Scripts are not supported under any Microsoft standard support program or service. The scripts are provided AS IS without warranty of any kind.
## Microsoft disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a 
## particular purpose. The entire risk arising out of the use or performance of the scripts and documentation remains with you. In no event shall
## Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever 
## (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary 
## loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility
## of such damages.
## Feedback: pbowden@microsoft.com

## This script is Jamf Pro compatible and can be pasted directly, without modification, into a new script window in the Jamf admin console.
## When running under Jamf Pro, no additional parameters need to be specified.

# Set sleep (wait) command if script is set to run at login and you are using NoMAD to get kerberos
sleep 20

# Shows tool usage and parameters
function ShowUsage {
	echo $TOOL_NAME - $TOOL_VERSION
	echo "Purpose: Detects UPN of logged-on user and pre-fills Office and Skype for Business Sign In page"
	echo "Usage: $0 [--Verbose]"
	echo
	exit 0
}

# Checks to see if the script is running as root
function RunningAsRoot {
	if [ "$EUID" = "0" ]; then
		echo "1"
	else
		echo "0"
	fi
}

# Returns the name of the logged-in user, which is useful if the script is running in the root context
function GetLoggedInUser {
	# The following line is courtesy of @macmule - https://macmule.com/2014/11/19/how-to-get-the-currently-logged-in-user-in-a-more-apple-approved-way/
	local LOGGEDIN=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
	if [ "$LOGGEDIN" == "" ]; then
		echo "0"
	else
		echo "$LOGGEDIN"
	fi
}

# HOME folder detection
function GetHomeFolder {
	HOME=$(dscl . read /Users/"$1" NFSHomeDirectory | cut -d ':' -f2 | cut -d ' ' -f2)
	if [ "$HOME" == "" ]; then
		if [ -d "/Users/$1" ]; then
			HOME="/Users/$1"
		else
			HOME=$(eval echo "~$1")
		fi
	fi
}

# Detects whether a given preference is managed
function IsPrefManaged {
	local PREFKEY="$1"
	local PREFDOMAIN="$2"
	local MANAGED=$(/usr/bin/python -c "from Foundation import CFPreferencesAppValueIsForced; print CFPreferencesAppValueIsForced('${PREFKEY}', '${PREFDOMAIN}')")
	if [ "$MANAGED" == "True" ]; then
		echo "1"
	else
		echo "0"
	fi
}

# Detect Kerberos cache
function DetectKerbCache {
	local KERB=$(${CMD_PREFIX} /usr/bin/klist 2> /dev/null)
	if [ "$KERB" == "" ]; then
		echo "0"
	else
		echo "1"
	fi
}

# Get the Kerberos principal from the cache
function GetPrincipal {
	local PRINCIPAL=$(${CMD_PREFIX} /usr/bin/klist | grep -o 'Principal: .*' | cut -d : -f2 | cut -d' ' -f2 2> /dev/null)
	if [ "$PRINCIPAL" == "" ]; then
		echo "0"
	else
		echo "$PRINCIPAL"
	fi
}

# Extract account name from principal
function GetAccountName {
	local PRINCIPAL="$1"
	echo "$PRINCIPAL" | cut -d @ -f1
}

# Extract domain name from principal
function GetDomainName {
	local PRINCIPAL="$1"
	echo "$PRINCIPAL" | cut -d @ -f2
}

# Get the defaultNamingContext from LDAP
function GetDefaultNamingContext {
	local DOMAIN="$1"
	local DOMAINNC=$(${CMD_PREFIX} /usr/bin/ldapsearch -H "ldap://$DOMAIN" -LLL -b '' -s base defaultNamingContext | grep -o 'defaultNamingContext:.*' | cut -d : -f2 | cut -d' ' -f2 2> /dev/null)
	if [ "$DOMAINNC" == "" ]; then
		echo "0"
	else
		echo "$DOMAINNC"
	fi
}

# Get the UPN for the user account
function GetUPN {
	local DOMAIN="$1"
	local NAMESPACE="$2"
	local ACCOUNT="$3"
	local UPN=$(${CMD_PREFIX} /usr/bin/ldapsearch -H "ldap://$DOMAIN" -LLL -b "$NAMESPACE" -s sub samAccountName=$ACCOUNT userPrincipalName | grep -o 'userPrincipalName:.*' | cut -d : -f2 | cut -d' ' -f2 2> /dev/null)
	if [ "$UPN" == "" ]; then
		echo "0"
	else
		echo "$UPN"
	fi
}

# Get the displayName for the user account
function GetDisplayName {
	local DOMAIN="$1"
	local NAMESPACE="$2"
	local ACCOUNT="$3"
	local DISPLAYNAME=$(${CMD_PREFIX} /usr/bin/ldapsearch -H "ldap://$DOMAIN" -LLL -b "$NAMESPACE" -s sub samAccountName=$ACCOUNT displayName | grep -o 'displayName:.*' | cut -d : -f2 | cut -c 2- 2> /dev/null)
	if [ "$DISPLAYNAME" == "" ]; then
		echo "0"
	else
		echo "$DISPLAYNAME"
	fi
}

# Parse initials from the displayName
function GetInitials {
	local DISPLAYNAME="$1"
	local FIRST=$(echo ${DISPLAYNAME} | cut -d ' ' -f1 | cut -c 1)
	local SECOND=$(echo ${DISPLAYNAME} | cut -d ' ' -f2 | cut -c 1)
	local THIRD=$(echo ${DISPLAYNAME} | cut -d ' ' -f3 | cut -c 1)
	local INITIALS=$(echo ${FIRST}${SECOND}${THIRD})
	if [ "$INITIALS" == "" ]; then
		echo "0"
	else
		echo "$INITIALS"
	fi
}

# Set Sign In keys
function SetPrefill {
	local UPN="$1"
	SetPrefillOffice "$UPN"
	SetPrefillSkypeForBusiness "$UPN"
	### Comment out the next line if you don't want to enable automatic sign in, or you are setting it separately in a Configuration Profile
	SetAutoSignIn
}

# Set Home Realm Discovery for Office apps
function SetPrefillOffice {
	local UPN="$1"
	local KEYMANAGED=$(IsPrefManaged "OfficeActivationEmailAddress" "com.microsoft.office")
	if [ "$KEYMANAGED" == "1" ]; then
		echo ">>ERROR - Cannot override managed preference 'OfficeActivationEmailAddress'"
	else
		${CMD_PREFIX} /usr/bin/defaults write com.microsoft.office OfficeActivationEmailAddress -string ${UPN}
		if [ "$?" == "0" ]; then
			echo ">>SUCCESS - Set 'OfficeActivationEmailAddress' to ${UPN}"
		else
			echo ">>ERROR - Did not set value for 'OfficeActivationEmailAddress'"
			exit 1
		fi
	fi
}

# Set Office Automatic Office Sign In
function SetAutoSignIn {
	local KEYMANAGED=$(IsPrefManaged "OfficeAutoSignIn" "com.microsoft.office")
	if [ "$KEYMANAGED" == "1" ]; then
		echo ">>WARNING - Cannot override managed preference 'OfficeAutoSignIn'"
	else
		${CMD_PREFIX} /usr/bin/defaults write com.microsoft.office OfficeAutoSignIn -bool TRUE
		if [ "$?" == "0" ]; then
			echo ">>SUCCESS - Set 'OfficeAutoSignIn' to TRUE"
		else
			echo ">>ERROR - Did not set value for 'OfficeAutoSignIn'"
			exit 1
		fi
	fi
}

# Set Office Username and Initials
function SetOfficeUser {
	local USERNAME="$1"
	local INITIALS="$2"
	if [ "$USERNAME" == "" ]; then
		echo ">>WARNING - Cannot set Office user name"
	else
		${CMD_PREFIX} /usr/bin/defaults write ${HOME}/Library/Group\ Containers/UBF8T346G9.Office/MeContact.plist Name -string "${USERNAME}"
		if [ "$?" == "0" ]; then
			echo ">>SUCCESS - Set Office user name to '${USERNAME}'"
		else
			echo ">>WARNING - Did not set Office user name'"
		fi
	fi
	if [ "$INITIALS" == "" ]; then
		echo ">>WARNING - Cannot set Office user initials"
	else
		${CMD_PREFIX} /usr/bin/defaults write ${HOME}/Library/Group\ Containers/UBF8T346G9.Office/MeContact.plist Initials -string "${INITIALS}"
		if [ "$?" == "0" ]; then
			echo ">>SUCCESS - Set Office user initials to '${INITIALS}'"
		else
			echo ">>WARNING - Did not set Office user initials'"
		fi
	fi
}

# Set Skype for Business Sign In
function SetPrefillSkypeForBusiness {
	local UPN="$1"
	local KEYMANAGED=$(IsPrefManaged "userName" "com.microsoft.SkypeForBusiness")
	if [ "$KEYMANAGED" == "1" ]; then
		echo ">>ERROR - Cannot override managed preference 'userName'"
	else
		${CMD_PREFIX} /usr/bin/defaults write com.microsoft.SkypeForBusiness userName -string ${UPN}
		if [ "$?" == "0" ]; then
			echo ">>SUCCESS - Set 'userName' to ${UPN}"
		else
			echo ">>ERROR - Did not set value for 'userName'"
			exit 1
		fi
	fi
	local SIP="$1"
	local KEYMANAGED=$(IsPrefManaged "sipAddress" "com.microsoft.SkypeForBusiness")
	if [ "$KEYMANAGED" == "1" ]; then
		echo ">>ERROR - Cannot override managed preference 'sipAddress'"
	else
		${CMD_PREFIX} /usr/bin/defaults write com.microsoft.SkypeForBusiness sipAddress -string ${SIP}
		if [ "$?" == "0" ]; then
			echo ">>SUCCESS - Set 'sipAddress' to ${SIP}"
		else
			echo ">>ERROR - Did not set value for 'sipAddress'"
			exit 1
		fi
	fi
}

# Detect Domain Join
function DetectDomainJoin {
	local DSCONFIGAD=$(${CMD_PREFIX} /usr/sbin/dsconfigad -show)
	if [ "$DSCONFIGAD" == "" ]; then
		echo "0"
	else
		echo "1"
	fi
}

# Detect Jamf presence
function DetectJamf {
	if [ -e "/Library/Preferences/com.jamfsoftware.jamf.plist" ]; then
		echo "1"
	else
		echo "0"
	fi
}

# Detect NoMAD presence
function DetectNoMAD {
	local NOMAD=$(${CMD_PREFIX} /usr/bin/defaults read com.trusourcelabs.NoMAD 2> /dev/null)
	if [ "$NOMAD" == "" ]; then
		echo "0"
	else
		echo "1"
	fi
}

# Get the UPN from NoMAD's preference cache
function GetUPNfromNoMAD {
	local NMUPN=$(${CMD_PREFIX} /usr/bin/defaults read com.trusourcelabs.NoMAD UserUPN 2> /dev/null)
	if [ "$NMUPN" == "" ]; then
		echo "0"
	else
		echo "$NMUPN"
	fi
}

# Get the DisplayName from NoMAD's preference cache
function GetDisplayNamefromNoMAD {
	local NMDISPLAYNAME=$(${CMD_PREFIX} /usr/bin/defaults read com.trusourcelabs.NoMAD DisplayName 2> /dev/null)
	if [ "$NMDISPLAYNAME" == "" ]; then
		echo "0"
	else
		echo "$NMDISPLAYNAME"
	fi
}

# Detect Enterprise Connect presence
function DetectEnterpriseConnect {
	local EC=$(${CMD_PREFIX} /usr/bin/defaults read com.apple.Enterprise-Connect 2> /dev/null)
	if [ "$EC" == "" ]; then
		echo "0"
	else
		echo "1"
	fi
}

# Get the UPN from Enterprise Connect (code courtesy of Dennis Browning)
function GetUPNfromEnterpriseConnect {
	local ECUPN=$(${CMD_PREFIX} "/Applications/Enterprise Connect.app/Contents/SharedSupport/eccl" -a userPrincipalName | awk '/userPrincipalName:/{print $NF}' 2> /dev/null)
	if [ "$ECUPN" == "" ]; then
		echo "0"
	else
		echo "$ECUPN"
	fi
}

# Evaluate command-line arguments
while [[ $# > 0 ]]
do
	key="$1"
	case "$key" in
    	--Help|-h|--help)
    	ShowUsage
    	exit 0
		shift # past argument
    	;;
    	--Verbose|-v|--verbose)
    	set -x
    	shift # past argument
    	;;
	esac
	shift # past argument or value
done

## Main
# Determine whether we need to use a sudo -u prefix when running commands
# NOTE: CMD_PREFIX is intentionally implemented as a global variable
CMD_PREFIX=""
ROOTLOGON=$(RunningAsRoot)
if [ "$ROOTLOGON" == "1" ]; then
	GetHomeFolder "$3"
	CURRENTUSER=$(GetLoggedInUser)
	if [ ! "$CURRENTUSER" == "0" ]; then
		echo ">>INFO - Script is running in the root security context - running commands as user: $CURRENTUSER"
		CMD_PREFIX="/usr/bin/sudo -u ${CURRENTUSER}"
	else
		echo ">>ERROR - Could not obtain the logged in user name"
		exit 1
	fi
fi

# Detect Active Directory connection style
DJ=$(DetectDomainJoin)
if [ "$DJ" == "1" ]; then
	echo ">>INFO - Detected that this machine is domain joined"
fi
NM=$(DetectNoMAD)
if [ "$NM" == "1" ]; then
	echo ">>INFO - Detected that this machine is running NoMAD"
fi
EC=$(DetectEnterpriseConnect)
if [ "$EC" == "1" ]; then
	echo ">>INFO - Detected that this machine is running Enterprise Connect"
fi

# Find out if a Kerberos principal and ticket is present
UPN="0"
KERBCACHE=$(DetectKerbCache)
if [ "$KERBCACHE" == "1" ]; then
	echo ">>INFO - Detected Kerberos cache"
	PRINCIPAL=$(GetPrincipal)
	if [ ! "$PRINCIPAL" == "0" ]; then
		echo ">>INFO - Detected Kerberos principal: $PRINCIPAL"
		# Get the account and domain name
		ACCOUNT=$(GetAccountName "$PRINCIPAL")
		DOMAIN=$(GetDomainName "$PRINCIPAL")
		# Find the default naming context for Active Directory
		NAMESPACE=$(GetDefaultNamingContext "$DOMAIN")
		if [ ! "$NAMESPACE" == "0" ]; then
			echo ">>INFO - Detected naming context: $NAMESPACE"
			# Now to get the UPN
			UPN=$(GetUPN "$DOMAIN" "$NAMESPACE" "$ACCOUNT")
			if [ ! "$UPN" == "0" ]; then
				echo ">>INFO - Found UPN: $UPN"
				SetPrefill "$UPN"
				DISPLAYNAME=$(GetDisplayName "$DOMAIN" "$NAMESPACE" "$ACCOUNT")
				if [ ! "$DISPLAYNAME" == "0" ]; then
					echo ">>INFO - Found DisplayName: $DISPLAYNAME"
					INITIALS=$(GetInitials "$DISPLAYNAME")
					SetOfficeUser "$DISPLAYNAME" "$INITIALS"
				fi
				exit 0
			else
				echo ">>WARNING - Could not find UPN"
			fi
		else
			echo ">>WARNING - Could not retrieve naming context"
		fi
	else
		echo ">>WARNING - Could not retrieve principal"
	fi
else
	echo ">>WARNING - No Kerberos cache present"
fi

# If we haven't got a UPN yet, see if we can get it from NoMAD's cache
if [ "$UPN" == "0" ] && [ "$NM" == "1" ]; then
	UPN=$(GetUPNfromNoMAD)
	if [ ! "$UPN" == "0" ]; then
		echo ">>INFO - Found UPN from NoMAD: $UPN"
		SetPrefill "$UPN"
		DISPLAYNAME=$(GetDisplayNamefromNoMAD)
			if [ ! "$DISPLAYNAME" == "0" ]; then
				echo ">>INFO - Found DisplayName from NoMAD: $DISPLAYNAME"
				INITIALS=$(GetInitials "$DISPLAYNAME")
				SetOfficeUser "$DISPLAYNAME" "$INITIALS"
			fi
		exit 0
	else
		echo ">>WARNING - Could not retrieve UPN from NoMAD"
	fi
fi

# If we still haven't got a UPN, see if we can get it from Enterprise Connect (code courtesy of Dennis Browning)
if [ "$UPN" == "0" ] && [ "$EC" == "1" ]; then
	UPN=$(GetUPNfromEnterpriseConnect)
	if [ ! "$UPN" == "0" ]; then
		echo ">>INFO - Found UPN from Enterprise Connect: $UPN"
		SetPrefill "$UPN"
		exit 0
	else
		echo ">>WARNING - Could not retrieve UPN from Enterprise Connect"
	fi
fi

# If we still haven't got a UPN yet, show an error
if [ "$UPN" == "0" ]; then
	echo ">>ERROR - Could not detect UPN"
	exit 1
fi

exit 0