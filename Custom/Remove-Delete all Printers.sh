#!/bin/sh

##Collect existing printers
    existingprinters=($(lpstat -p | awk '{print $2}' > /tmp/existingprinters.txt))

##Delete existing printers
    IFS=$'\n'
        declare -a existingprinters=($(lpstat -p | awk '{print $2}'))
    unset IFS

    for i in "${existingprinters[@]}"
    do
        echo Deleting $i
        lpadmin -x $i
    done