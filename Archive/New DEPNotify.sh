#!/bin/bash

#################################################################################
# This script was created with love and compassion. ❤️
# Jordan was here
# December 2021
#################################################################################
# Ensuring that the authchanger command is set to implement the notify window
# if you wish to run the Notify screen before logging in change flag to -preAuth

/usr/local/bin/authchanger -reset -AD -preAuth NoMADLoginAD:Notify 

# Reloading the login window
/usr/bin/killall -HUP loginwindow

# Variables for File Paths
JAMF_BINARY="/usr/local/bin/jamf"
DEP_NOTIFY_CONFIG="/var/tmp/depnotify.log"
TMP_DEBUG_LOG="/var/tmp/depNotifyDebug.log"

#########################################################################################
# Variables to change/modify
#########################################################################################
# Testing flag will enable the following things to change:
# - Auto removal of BOM files to reduce errors
# - Sleep commands instead of polcies being called
# - Quit Key set to command + control + x
TESTING_MODE=false # Set variable to true or false

# Banner image can be 600px wide by 100px high. Images will be scaled to fit
# If this variable is left blank, the generic image will appear
BANNER_IMAGE_PATH=""

# Main heading that will be displayed under the image
# If this variable is left blank, the generic banner will appear
BANNER_TITLE="Welcome to Mount Albert Grammar School"

# Paragraph text that will display under the main heading. For a new line, use \n
# this variable is left blank, the generic message will appear. Leave single
# quotes below as double quotes will break the new line.
MAIN_TEXT='This Mac is now finding and installing the apps and settings it needs.  \n \n If you need any further apps or software you can easily find them within the Self Service app located on your Dock. \n \n Please do not shut down, restart, close or unplug this Mac until the process is complete.'

# The policy array must be formatted "Progress Bar text,customTrigger". These will be
# run in order as they appear below.
  POLICY_ARRAY=(
  	",Install Apple Rosetta"
    ",Rename Computer"
    ",AutoUpdate-NoMAD"
    ",Install NoMAD LaunchAgent"
    ",Install FindMe Printers"
    ",Install PaperCut Client"
    ",AutoUpdate-Microsoft Word"
    ",AutoUpdate-Microsoft Excel"
    ",AutoUpdate-Microsoft PowerPoint"
    ",AutoUpdate-Microsoft Outlook"
    ",AutoUpdate-Microsoft OneNote"
    ",Install F5Access LaunchAgent"
    ",AutoUpdate-VLC"
    ",Install KAMAR Opener"
    ",Install FileMaker Pro"
    ",Enable Screen Sharing"
    ",Enrollment Apple Software Update"
  )

# Text that will display in the progress bar
  INSTALL_COMPLETE_TEXT="Setup Complete!"

# Text that will displaya inside the alert once policies have finished
  COMPLETE_ALERT_TEXT="This Mac is now finished and ready to go! \n \n This Mac will now restart in 1 minute to complete the last few updates."

########################################################################
# Main Script
########################################################################

# Caffeinating

echo "Time to caffeniate..."
caffeinate -d -i -m -s -u &

# Configure DEPNotify starting window
# Setting custom image if specified
  if [ "$BANNER_IMAGE_PATH" != "" ]; then
    echo "Command: Image: $BANNER_IMAGE_PATH" >> "$DEP_NOTIFY_CONFIG"
  fi

# Setting custom title if specified
  if [ "$BANNER_TITLE" != "" ]; then
    echo "Command: MainTitle: $BANNER_TITLE" >> "$DEP_NOTIFY_CONFIG"
  fi

# Setting custom main text if specified
  if [ "$MAIN_TEXT" != "" ]; then
    echo "Command: MainText: $MAIN_TEXT" >> "$DEP_NOTIFY_CONFIG"
  fi

# Validating true/false flags
  if [ "$TESTING_MODE" != true ] && [ "$TESTING_MODE" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Testing configuration not set properly. Currently set to '$TESTING_MODE'. Please update to true or false." >> "$TMP_DEBUG_LOG"
    exit 1
  fi

# Checking policy array and adding the count from the additional options above.
ARRAY_LENGTH="$((${#POLICY_ARRAY[@]}+ADDITIONAL_OPTIONS_COUNTER))"
echo "Command: Determinate: $ARRAY_LENGTH" >> "$DEP_NOTIFY_CONFIG"

# Loop to run policies
for POLICY in "${POLICY_ARRAY[@]}"; do
    echo "Status: $(echo "$POLICY" | cut -d ',' -f1)" >> "$DEP_NOTIFY_CONFIG"
    if [ "$TESTING_MODE" = true ]; then
      sleep 10
    elif [ "$TESTING_MODE" = false ]; then
      "$JAMF_BINARY" policy -event "$(echo "$POLICY" | cut -d ',' -f2)"
    fi
done

# Exit gracefully after things are finished
echo "Status: $INSTALL_COMPLETE_TEXT" >> "$DEP_NOTIFY_CONFIG"
echo "Command: RestartNow: $COMPLETE_ALERT_TEXT" >> "$DEP_NOTIFY_CONFIG"
exit 0