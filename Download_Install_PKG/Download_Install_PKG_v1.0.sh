#!/bin/sh
#
# ABOUT THIS PROGRAM
#
# NAME
#	Download_Install_PKG.sh -- Downloads and installs pkgs from a URL
#
# SYNOPSIS
#	sudo Download_Install_PKG.sh
#
# DESCRIPTION
#	This script will download a pkg from a URL and install it.  The script assumes that
#	the below path exists to download the pkg installer
#
#		/Library/Application Support/JAMF/Downloads/
#
#	Step 1: Create a policy to install the DMG:
#		1.  Add script to policy.
#		2.  Add download URL to your PKG into parameter 4
#		3.  Optional add forcesuccessflag without quotes "YES" into parameter 5	    
#		4. Click Save.
#
####################################################################################################
#
# HISTORY
#
#	Version: 1.0
#
#	- Created by Blake Suggett on Feburary 5, 2026
#
####################################################################################################
#
# DEFINE VARIABLES & READ IN PARAMETERS
#
#####################################################################################################
#
# HARDCODED VALUES SET HERE
#
# Variables set by Jamf Pro - To manually override, remove the comment for the given variable
#
# targetDrive=""   # Jamf Pro will pass this parameter as "Target Drive" if left commented out
# computerName=""  # Jamf Pro will pass this parameter as "Computer Name" if left commented out
# userName=""  	   # Jamf Pro will pass this parameter as "User Name" if left commented out. Usernames
#				   can only be passed if the script is triggered at login, logout, or by Self Service.
#
#####################################################################################################

####################################################################################################
# DEFINE VARIABLES & READ IN PARAMETERS
#####################################################################################################
downloadURL=""
forcesuccessflag=""
pkgName=""

# CHECK TO SEE IF A VALUE WERE PASSED IN FOR PARAMETERS AND ASSIGN THEM
if [ "${1}" != "" ] && [ "${targetDrive}" == "" ]; then
    targetDrive="${1}"
fi

if [ "${2}" != "" ] && [ "${computerName}" == "" ]; then
    computerName="${2}"
fi

if [ "${3}" != "" ] && [ "${userName}" == "" ]; then
    userName="${3}"
fi

if [ "${4}" != "" ] && [ "${downloadURL}" == "" ]; then
    downloadURL="${4}"
fi

if [ "${5}" != "" ] && [ "${forcesuccessflag}" == "" ]; then
    forcesuccessflag="${5}"
fi

####################################################################################################
# LOGGING FUNCTION
####################################################################################################
logFile="/private/var/log/jamf.log"
log () {
	echo $1
	echo $(date "+%a %b %d %H:%M:%S $HOSTNAME ScriptOutput: ") $1 >> $logFile	
}
####################################################################################################
# VARIABLE VERIFICATION FUNCTION
####################################################################################################
verifyVariable () {
eval variableValue=\$$1
if [ "${variableValue}" != "" ]; then
	log "Variable \"$1\" value is set to: \"$variableValue\""
else
	log "Variable \"$1\" is blank.  Please assign a value to the variable."
	exit 1
fi
}
verifyVariableYESorNo () {
	eval VariableYESorNoValue=\$$1
	if [[ "$VariableYESorNoValue" == "YES" ]]; then
		log "Variable \"$1\" explicitly declared...: $VariableYESorNoValue"
	else
		log "Variable \"$1\" not explicitly declared, defaulting to no/ignoring..."
	fi
	log ""
}
####################################################################################################
# OTHER FUNCTIONS
####################################################################################################
obtain_pkg_filename_from_download_url () {
	pkg_filename_from_download_url="${1}"
	log "Obtaining PKG filename from URL Header..."
	if curl --output /dev/null --silent --head --fail "${pkg_filename_from_download_url}"; then
		pkgName=$(curl -sI "${pkg_filename_from_download_url}" | grep -i "Location" | sed 's:.*/::' | sed 's/%20/ /g')
  		if [[ ! -n "${pkgName}" ]]; then
  			log "Not found at URL header... Trying in URL for filename..."
  			pkgName=$(echo "${pkg_filename_from_download_url}" | sed 's:.*/::' | sed 's/%20/ /g')
  		fi
  		if [[ ! -n "${pkgName}" ]]; then
  			log "ERROR - Couldn't obtain PKG filename"
  			log ""
  			exit 1
  		else
  			log "Found...: ${pkgName}"
  			log ""
  		fi
	else
		log "Couldn't connect to URL header... Trying in URL for filename..."
		pkgName=$(echo "${pkg_filename_from_download_url}" | sed 's:.*/::' | sed 's/%20/ /g')
		if [[ ! -n "${pkgName}" ]]; then
  			log "ERROR - Couldn't obtain PKG filename"
  			log ""
  			exit 1
  		else
  			log "Found...: ${pkgName}"
  			log ""
  		fi
  	fi
}
sanitize() {
  printf '%s' "$1" | tr -d '\r\n'
}
####################################################################################################
# SCRIPT 
####################################################################################################
log "Download_Install_PKG.sh"
log ""

verifyVariable downloadURL
verifyVariableYESorNo forcesuccessflag
obtain_pkg_filename_from_download_url "${downloadURL}"
full_path_to_pkgName=$(echo "/Library/Application Support/JAMF/Downloads/${pkgName}")
full_path_to_pkgName=$(sanitize "$full_path_to_pkgName")

# Start Download
log "Downloading file to...: ${full_path_to_pkgName}"
curl -L -o "${full_path_to_pkgName}" "${downloadURL}" --silent
if [[ "$?" == 0 ]]; then
	log "Successful"
	log ""
else
	log "ERROR - Downloading file"
	log ""
    exit 1
fi

# Start Install
log "Installing package...: ${pkgName}"
log "Install string...: installer -pkg \"${full_path_to_pkgName}\" -target /"
installer -pkg "${full_path_to_pkgName}" -target /
PKGExitCode=($?)
log ""
if [[ "$forcesuccessflag" == "YES" ]]; then
	log "PKG exit code was: $PKGExitCode"
	log "Forced Exit code 0 was passed to JSS"
	log ""
	rm -f "${full_path_to_pkgName}"
	exit 0
else
	log "PKG exit code was...: $PKGExitCode"
    log "Exit code $PKGExitCode was passed to JSS"
    log ""
	rm -f "${full_path_to_pkgName}"
    exit $PKGExitCode
fi
