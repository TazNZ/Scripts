#!/bin/bash

## Script parameters
Title="$4"            ## Title for Yo notification (Required)
Msg="$5"              ## Message for Yo notification (Required)
Btn="$6"              ## Custom button name (Optional, but button name should be set if using a button action)
BtnAct="$7"           ## Action for button (Optional)

## Path to the script to run
scriptRunDir="/private/var/scripts/"

## Create the directory to house the script if not present
if [ ! -d "$scriptRunDir" ]; then
    mkdir -p "$scriptRunDir"
fi

## Path to Yo.app or custom version of the tool. Must include path to the executable
Yoapp="/Applications/Utilities/yo.app/Contents/MacOS/Yo"

## Check to make sure the app is where it should be or we can't do much
if [ ! -e "$Yoapp" ]; then
    echo "Yo application could not be found in the expected location. Must exit."
    exit 1
fi

## Check to make sure a title and message string were passed to the script
if [[ -z "$Title" ]] || [[ -z "$Msg" ]]; then
    echo "Either the Title or Message strings have been left blank. Please enter a value for Title in \$4 and a message value in \$5 and try again."
    exit 1
fi

## Get Logged in User name
loggedInUser=$(stat -f%Su /dev/console)

## Get Logged in User UID
loggedInUID=$(id -u "$loggedInUser")

## Make sure someone is logged in or no message display is possible
if [[ "$loggedInUser" == "root" ]] && [[ "$loggedInUID" == 0 ]]; then
    echo "No user is logged in. Skipping display of notification until next run."
    exit 0
fi

## This function runs the temp script as the logged in user
function runScriptAsUser ()
{

/bin/launchctl asuser "$loggedInUID" sudo -iu "$loggedInUser" "/private/var/scripts/Yo_run.sh"

}

## This function creates a temp script to run Yo with the parameters and text strings passed to the main script
function createScript ()
{

cat << EOD > /private/var/scripts/Yo_run.sh
#!/bin/bash

$(echo "${contents}")

EOD

/bin/chmod +x /private/var/scripts/Yo_run.sh

runScriptAsUser

}


## Create the script contents based on if a button string was passed and/or a button action was also passed
if [[ ! -z "$Btn" ]] && [[ ! -z "$BtnAct" ]]; then
    echo "Creating notice with button + action"
    contents="\"${Yoapp}\" -t \"${Title}\" -n \"${Msg}\" -b \"${Btn}\" -B \"${BtnAct}\" -z \"None\" -p"
    createScript
elif [[ ! -z "$Btn" ]] && [[ -z "$BtnAct" ]]; then
    echo "Creating notice with button only"
    contents="\"${Yoapp}\" -t \"${Title}\" -n \"${Msg}\" -b \"${Btn}\" -z \"None\" -p"
    createScript
elif [[ -z "$Btn" ]]; then
    echo "Creating notice with no custom button"
    contents="\"${Yoapp}\" -t \"${Title}\" -n \"${Msg}\" -z \"None\" -p"
    createScript
fi