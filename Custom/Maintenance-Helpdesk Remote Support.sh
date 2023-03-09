#!/bin/bash

if [ ! -d "/Applications/TeamViewerQS.app" ]; then
  /usr/local/bin/jamf policy -event "AutoUpdate-TeamViewerQS"
  sleep 2
  open /Applications/TeamViewerQS.app
else
	open /Applications/TeamViewerQS.app
fi
exit 0