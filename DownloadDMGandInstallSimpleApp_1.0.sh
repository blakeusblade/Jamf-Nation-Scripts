#!/bin/sh
####################################################################################################
# CREATOR BLAKE SUGGETT
# SCRIPT LAST MODIFIED BY BLAKE SUGGETT
#
# References:
####################################################################################################
# - What the script does
# 
# * Downloads a DMG using curl from a URL
# * Mounts the DMG
# * Uninstall/removes any .app found in the /Applications directory that matches the .app name within
#   the DMG
# * Install/ditto the .app into the /Applciations directory
# * Conditionally, recursively removes extended attributes from .app
#
# - How to use
#
# - Paramater 4 - REQUIRED
#     Pass into parameter 4 the URL for the DMG download. The client will use curl to download the DMG
#     file into the /Library/Application Support/JAMF/Downloads directory.
# - Parameter 5 - REQUIRED
#     Pass into parameter 5 the DMG filename exactly as it appears in the URL in paramater 4
# - Parameter 6 - OPTIONAL
#     Pass into parameter 6 with "YES" in uppercase without quotes if one wants extended attritbues
#     removed. This is useful as sometimes vendor DMGs contain .app with extended attributes and abnormal
#     app behavior occurs when root was used to place the .app in the applications directory.
#
####################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
#####################################################################################################
# Variables used for logging
ScriptName="DownloadDMGandInstallSimpleApp_1.0.sh"
logFile="/private/var/log/jamf.log"

# Variables used by this script.
downloadURL=""
dmgName=""
removeEAs=""

# CHECK TO SEE IF A VALUE WERE PASSED IN FOR PARAMETERS AND ASSIGN THEM
if [ "$1" != "" ] && [ "$targetDrive" == "" ]; then
    targetDrive="$1"
fi

if [ "$2" != "" ] && [ "$computerName" == "" ]; then
    computerName="$2"
fi

if [ "$3" != "" ] && [ "$userName" == "" ]; then
    userName="$3"
fi

if [ "${4}" != "" ] && [ "${downloadURL}" == "" ]; then
    downloadURL="${4}"
fi

if [ "${5}" != "" ] && [ "${dmgName}" == "" ]; then
    dmgName="${5}"
fi

if [ "${6}" != "" ] && [ "${removeEAs}" == "" ]; then
    removeEAs="${6}"
fi

####################################################################################################
# 
# LOGGING FUNCTION
#
####################################################################################################
log () {
	echo $1
	echo $(date "+%a %b %d %H:%M:%S $HOSTNAME ScriptOutput: ") $1 >> $logFile	
}

####################################################################################################
# 
# VARIABLE VERIFICATION FUNCTION
#
####################################################################################################

verifyVariable () {
eval variableValue=\$$1
if [ "${variableValue}" != "" ]; then
	log "Variable \"${1}\" value is set to: ${variableValue}"
else
	log "Variable \"${1}\" is blank.  Please assign a value to the variable."
	exit 1
fi
}
verifyVariableYESorNo () {
eval VariableYESorNoValue=\$$1
	if [[ "${VariableYESorNoValue}" == "YES" ]]; then
		log "Variable \"${1}\" explicitly declared...: ${VariableYESorNoValue}"
	else
		log "Variable \"${1}\" not explicitly declared, defaulting to no/ignoring..."
	fi
}

####################################################################################################
# 
# VERIFY VARIABLES 
#
####################################################################################################
log "$ScriptName"
log ""

verifyVariable downloadURL
verifyVariable dmgName
verifyVariableYESorNo removeEAs
log ""
# Checking download URL
log "Checking connection to downloadURL..."
if curl --output /dev/null --silent --head --fail "${downloadURL}"; then
  log "Successful"
else
  log "ERROR - Can't connect to downloadURL"
  exit 1
fi
# Checking downloads directory exists
log "Checking downloads directory...: /Library/Application Support/JAMF/Downloads"
if [[ -d "/Library/Application Support/JAMF/Downloads" ]]; then
	log "Found..."
else
	log "Missing... Creating..."
  mkdir -p /Library/Application\ Support/JAMF/Downloads
  if [[ "$?" != 0 ]]; then
  	log "ERROR - mkdir failed"
    exit 1
  fi
  chown -R root:wheel /Library/Application\ Support/JAMF/Downloads
  if [[ "$?" != 0 ]]; then
  	log "ERROR - chown failed"
    exit 1
  fi
  chmod -R 700 /Library/Application\ Support/JAMF/Downloads
  if [[ "$?" != 0 ]]; then
  	log "ERROR - chmod failed"
    exit 1
  fi
  if [[ -d "/Library/Application Support/JAMF/Downloads" ]]; then
  	log "Successful"
  fi
fi
log ""

####################################################################################################
# 
#  MOUNT & UNMOUNT FUNCTIONS
#
####################################################################################################

mountDMG () {
# Mount DMG
log "Mounting DMG...: /Library/Application Support/JAMF/Downloads/${dmgName}"
mountResult=`hdiutil mount -private -noautoopen -noverify "/Library/Application Support/JAMF/Downloads/${dmgName}" -shadow`
if [[ "$?" == 0 ]];
then
	mountDevice=`echo $mountResult | head -1 | awk '{print $1}'`
	mountVolume=`echo $mountResult | grep -o "/Volumes.*"`
    log "DMG mounted successfully as volume ${mountVolume} on device ${mountDevice}"
else
	log "ERROR - hdiutil exit code: $?"
    exit 1
fi
log ""
}

unmountDMG () {
	# Unmount DMG
    log "Unmounting DMG...: /Library/Application Support/JAMF/Downloads/${dmgName}"
    hdiutil detach ${mountDevice} -force > /dev/null 2>&1
    if [[ "$?" == 0 ]]; then
    	log "Success - hdiutil detach ${mountVolume}/ force"
    else
        log "ERROR - hdiutil detach ${mountVolume}/ force"
        diskutil unmountDisk force ${mountDevice} > /dev/null 2>&1
    	if [[ "$?" == 0 ]]; then
    		log "Success - diskutil unmountDisk force ${mountVolume}/"
    	else
    		log "ERROR - diskutil unmountDisk force ${mountVolume}/"
    	fi
    fi
    # Cleanup dmg shadow file
    if [[ -f "/Library/Application Support/JAMF/Downloads/${dmgName}.shadow" ]]; then
    	rm -f "/Library/Application Support/JAMF/Downloads/${dmgName}.shadow"
    fi
    # Cleanup dmg file
    if [[ -f "/Library/Application Support/JAMF/Downloads/${dmgName}" ]]; then
    	rm -f "/Library/Application Support/JAMF/Downloads/${dmgName}"
	fi
    log ""
}

removeDMG () {
	# Remove DMG
    rm -f "/Library/Application Support/JAMF/Downloads/${dmgName}" > /dev/null 2>&1
    if [[ "$?" == 0 && ! -f "/Library/Application Support/JAMF/Downloads/${dmgName}" ]]; then
    	log "Successfully removed"
    else
    	log "ERROR - Removing DMG file"
        exit 1
    fi
    log ""
}

####################################################################################################
# 
# SCRIPT 
#
####################################################################################################

if [[ -f "/Library/Application Support/JAMF/Downloads/${dmgName}" ]]; then
    removeDMG
fi

# Downloading file
log "Downloading file..."
pushd "/Library/Application Support/JAMF/Downloads" > /dev/null
curl -O "${downloadURL}" --silent
if [[ "$?" == 0 ]];
then
	log "Successful"
else
	log "ERROR - Downloading file"
    exit 1
fi

# Checking file downloaded correctly
log "Checking downloaded file...: /Library/Application Support/JAMF/Downloads/${dmgName}"
if [[ -f "/Library/Application Support/JAMF/Downloads/${dmgName}" ]];
then
	log "Successful"
else
	log "ERROR - File doesn't exist"
    exit 1
fi

log ""

mountDMG

# Get .app name from within DMG
log "Retrieving .app from within DMG..."
appName=`ls "${mountVolume}" | grep \.app$ | head -1`
if [[ ! -z "${appName}" ]];
then
	log "App found...: ${appName}"
else
	log "ERROR - No .app file found"
    unmountDMG
    exit 1
fi

# Install logic
log "Checking for an existing .app in /Applications/..."
if [[ ! -d "/Applications/${appName}" ]];
then
	# Not found - Install
	log "Not found. Installing..."
    ditto "${mountVolume}/${appName}" "/Applications/${appName}"
    if [[ "$?" == 0 && -d "/Applications/${appName}" ]];
    then
    	log "Successfully installed"
    	if [[ "${removeEAs}" == "YES" ]]; then
        	log "Removing extended attributes..."
        	xattr -rc "/Applications/${appName}/" > /dev/null 2>&1
        	if [[ "$?" == 0 ]]; then
        		log "Successful"
        	else
        		log "WARING! - Extended attributes couldn't be removed"
        	fi
    	fi
    else
    	log "ERROR - ditto into /Applications directory"
    	unmountDMG
    	exit 1
    fi
    log ""
else
	# Found - Remove before install
	log "Found. Removing..."
    rm -Rf "/Applications/${appName}"
    if [[ "$?" == 0 && ! -d "/Applications/${appName}" ]];
    then
    	log "Successfully removed"
        log "Installing..."
        ditto "${mountVolume}/${appName}" "/Applications/${appName}"
        if [[ "$?" == 0 && -d "/Applications/${appName}" ]];
    	then
    		log "Successfully installed"
    		if [[ "${removeEAs}" == "YES" ]]; then
          log "Removing extended attributes..."
          xattr -rc "/Applications/${appName}/" > /dev/null 2>&1
          if [[ "$?" == 0 ]]; then
          	log "Successful"
          else
        	log "WARING! - Extended attributes couldn't be removed"
          fi
      fi
    	else
    		log "ERROR - ditto into /Applications directory"
    	fi
    else
    	log "ERROR - removing from /Applications directory"
        unmountDMG
        exit 1
    fi
    log ""
fi
unmountDMG
