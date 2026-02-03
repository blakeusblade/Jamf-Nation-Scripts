#!/bin/sh
####################################################################################################
#
# Copyright (c) 2011, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#####################################################################################################
#
# SUPPORT FOR THIS PROGRAM
#
#       This program is distributed "as is" by JAMF Software, LLC's Resource Kit team. For more
#       information or support for the Resource Kit, please utilize the following resources:
#
#               http://list.jamfsoftware.com/mailman/listinfo/resourcekit
#
#               http://www.jamfsoftware.com/support/resource-kit
#
#       Please reference our SLA for information regarding support of this application:
#
#               http://www.jamfsoftware.com/support/resource-kit-sla
#
#####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#	installPKGsfromDMG.sh -- Installs PKGs or MPKGs wrapped inside a DMG
#
# SYNOPSIS
#	sudo installPKGsfromDMG.sh
#
# DESCRIPTION
#	This script will mount a DMG and install PKG files wrapped inside.  The script assumes that
#	the DMG has been previously cached to the machine to:
#
#		/Library/Application Support/JAMF/Waiting Room/
#
#	This is the default location that a package will be cached to when selecting the "Cache"
#	option within a policy or Casper Remote.
#
#	To use this script, please follow the following workflow:
#
#	Step 1: Wrap PKGs inside a DMG
#		1.  Open Disk Utility.
#		2.  Navigate to File > New > Disk Image from Folder.
#		3.  Select the directory/folder and click the Image button.
#		4.  Name the DMG after the original PKG or accordingly. Its heavily desired to have no
#			spaces or special characters in the volume and or filename.
#		5.  Choose a location for the package and then click Save.
#
#	Step 2: Upload the DMG and installPKGsfromDMG.sh script to the Jamf Pro WebUI:
#
#	Step 3: Create a policy to install the DMG:
#		1.  Log in to the Jamf Pro WebUI with a web browser.
#		2.  Click the Management tab.
#		3.  Click the Policies link.
#		4.  Click the Create Policy button.
#		5.  Select the Create policy manually option and click Continue.
#		6.  Configure the options on the General and Scope panes as needed.
#		7.  Click the Packages button, and then click the Add Package link.
#		8.  Across from DMG, choose “Cache” from the Action pop-up menu and then click the 
#		    "Add Packages" button.
#		9.  Click the Scripts button, and then click the Add Script link.
#		10. Across from the installPKGsfromDMG.sh script, choose “Run After” from the Action pop-up menu.
#		11. Enter the name of the original DMG in the Parameter 4 field.		    
#		12. Click Save.
#
####################################################################################################
#
# HISTORY
#
#	Version: 9.0
#
#	- Created by Nick Amundsen on July 22, 2011
#   - Modified by Blake Suggett on March 2, 2020
#	- Modified by Blake Suggett on June 25, 2025
#	- Modified by Blake Suggett on January 20, 2026
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
# targetDrive=""  # Jamf Pro will pass this parameter as "Target Drive" if left commented out
# computerName=""  # Jamf Pro will pass this parameter as "Computer Name" if left commented out
# userName=""  # Jamf Pro will pass this parameter as "User Name" if left commented out. Usernames
#				   can only be passed if the script is triggered at login, logout, or by Self Service
#####################################################################################################

# Variables used for logging
logFile="/private/var/log/jamf.log"

# Variables used by this script.
dmgName="" # PARAMETER 4 # MANDATORY - Supply fullpath to DMG or DMG filename to use.
forcesuccessflag="" # PARAMETER 5 # OPTIONAL - eg YES in uppercase. Allows the script to force an exit code of zero to JAMF Pro. The PKG exit code will be recorded in policy logs  

unassigned_6="" # PARAMETER 6 # Unused parameter - Previously useinstallerapp, now default behaviour.

allowUntrusted="" # PARAMETER 7 # OPTIONAL - eg YES in uppercase. Allows the installation of PKGs or MPKGs that have expired certificates. Dependant on variable useinstallerapp
applyChoiceChangesXMLFile="" # PARAMETER 8 # OPTIONAL - eg mychoicechanges.xml. This allows one to pass a xml answer file to a PKG for custom installations

unassigned_9="" # PARAMETER 9 # Unused parameter - Previously multiPKGs, now default behaviour will loop through PKGs or MPKGs (that are NOT hidden using chflags) running installations
unassigned_10="" # Unused parameter
unassigned_11="" # Unused parameter

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
if [ "${4}" != "" ] && [ "${dmgName}" == "" ]; then
    dmgName="${4}"
fi
if [ "${5}" != "" ] && [ "${forcesuccessflag}" == "" ]; then
    forcesuccessflag="${5}"
fi
if [ "${6}" != "" ] && [ "${unassigned_6}" == "" ]; then
    unassigned_6="${6}"
fi
if [ "${7}" != "" ] && [ "${allowUntrusted}" == "" ]; then
    allowUntrusted="${7}"
fi
if [ "${8}" != "" ] && [ "${applyChoiceChangesXMLFile}" == "" ]; then
    applyChoiceChangesXMLFile="${8}"
fi
if [ "${9}" != "" ] && [ "${unassigned_9}" == "" ]; then
    unassigned_9="${9}" 
fi
if [ "${10}" != "" ] && [ "${unassigned_10}" == "" ]; then
    unassigned_10="${10}"
fi
if [ "${11}" != "" ] && [ "${unassigned_11}" == "" ]; then
    unassigned_11="${11}"
fi

####################################################################################################
# LOGGING FUNCTION
####################################################################################################
log () {
	echo $1
	echo $(date "+%a %b %d %H:%M:%S $HOSTNAME ScriptOutput: ") $1 >> $logFile	
}

####################################################################################################
# VARIABLE VERIFICATION FUNCTIONS
####################################################################################################
verifyVariable () {
	eval variableValue=\$$1
	if [ "$variableValue" != "" ]; then
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
}
verifyVariable_DMG_is_full_path () {
	eval verifyVariable_DMG_is_full_path=\$$1
	if [[ "$verifyVariable_DMG_is_full_path" == */* ]]; then
    	# Check if the path exists
    	if [[ -f "$verifyVariable_DMG_is_full_path" ]]; then
      		log "Verifying custom \"DMG path\"...: valid"
    	else
      		log "Verifying custom \"DMG path\"...: invalid/not found."
      		exit 1
    	fi
	else
		if [[ -f "/Library/Application Support/JAMF/Waiting Room/$verifyVariable_DMG_is_full_path" ]]; then
			log "Verifying default \"DMG path\"...: valid"
			dmgName=$(echo "/Library/Application Support/JAMF/Waiting Room/${dmgName}")
		else
			log "Verifying default \"DMG path\" ...: invalid/not found."
			exit 1
		fi
  	fi
}
####################################################################################################
# OTHER FUNCTIONS
####################################################################################################
MountDMG () {
	dmg_file="$1"
	# Mount the DMG
	log "Mounting DMG...: \"${dmg_file}\""
	mountResult=$(/usr/bin/hdiutil mount -private -noautoopen -noverify "${dmg_file}" -shadow)
	if [[ "$?" == 0 ]] ; then
		mountVolume=$(echo "$mountResult" | grep -o "/Volumes.*")
		mountDevice=$(echo "${mountResult}" | head -1 | awk '{print $1}')
		log "DMG mounted successfully as volume \"${mountVolume}\" on device \"${mountDevice}\"."
		log ""
	else
		log "There was an error mounting the DMG. mountResult hdiutil exit code: $?"
		log ""
		exit 1
	fi
}
UnmountDMG () {
	# Unmount the DMG
    log "Unmounting device \"${mountDevice}\" volume \"${mountVolume}\"."
    hdiutil detach "${mountDevice}" -force
    UnmountDMGExitCode=($?)
    if [[ "$UnmountDMGExitCode" == 0 ]]; then
        log "Successfully unmounted"
        if [[ "$dmgName" == *"/Library/Application Support/JAMF"* || "$dmgName" == *"/private/tmp"* || "$dmgName" == *"/private/var/tmp"* || "$dmgName" == *"/tmp/"* ]]; then
        	rm -f "${dmgName}" 
			rm -f "${dmgName}.shadow"
		fi
    else
    	log "Unable to unmount. hdiutil exit code : $UnmountDMGExitCode"
    fi
    log ""
	rm -f "${dmgName}.shadow"
}
GetPackages() {
    # Gets all pkgs that are NOT HIDDEN (chflags hidden ~/some/path/install.pkg)
    packageNames=()
    counter=0
    files=$(ls "${mountVolume}" | grep "pkg")
    while IFS= read -r file; do
        if ! ls -lO "${mountVolume}/${file}" 2>/dev/null | grep -q hidden; then
            packageNames+=("$file")
            #echo "$file"
            ((counter++))
        fi
    done <<< "$files"
    number_of_packages_to_be_installed=$(echo "$counter")
    if [[ "$number_of_packages_to_be_installed" -gt 1 ]]; then
        counter=0
    elif [[ "$number_of_packages_to_be_installed" -eq 1 ]]; then
        packageName="${packageNames[0]}"
        counter=0
    else
        log "ERROR - No pkgs or mpkgs were found."
        UnmountDMG
        exit 1
    fi
}
####################################################################################################
# RUN VARIABLE VERIFICATION FUNCTIONS
####################################################################################################
log "installPKGsfromDMG.sh"
log ""

verifyVariable dmgName
verifyVariable_DMG_is_full_path dmgName
verifyVariableYESorNo forcesuccessflag
verifyVariableYESorNo allowUntrusted
if [[ -z "$applyChoiceChangesXMLFile" ]]; then
	log "Variable \"applyChoiceChangesXMLFile\" not declared..."
else
	log "Variable \"applyChoiceChangesXMLFile\" declared...: ${applyChoiceChangesXMLFile}"
fi
log ""

####################################################################################################
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
####################################################################################################
MountDMG "${dmgName}"
GetPackages
if [[ "$number_of_packages_to_be_installed" -gt 1 && ! -z "$applyChoiceChangesXMLFile" ]]; then
	log "ERROR - Number of packages to be installed...: Greater than 1 and applyChoiceChangesXMLFile is declared"
	log ""
	UnmountDMG
    exit 1
elif [[ "$number_of_packages_to_be_installed" -gt 1 ]]; then
	# Run multiple PKG installations based on passed parameters
	log "Number of packages to be installed...: $number_of_packages_to_be_installed"
	log ""
	if [[ "$allowUntrusted" == "YES" ]]; then
		log "Installing packages, allowing untrusted PKGs... Only failures will be logged..."
		log "Install string...: installer -pkg \"${mountVolume}/LotsOfPackages.pkg\" -target / -allowUntrusted"
		log ""
		IFS=$'\n'
		for package in ${packageNames[@]}
		do
			#log "Installing ${mountVolume}/${package}..."
            installer -pkg "${mountVolume}/${package}" -target / -allowUntrusted > /dev/null 2>&1
			if [[ $? != 0 ]] ; then
				log "${package} FAILED"
				counter=$((counter+1))
				# The line below is only to trick the loop into continuing if the installation failed.
				fakecommand_thatdoesntexist > /dev/null 2>&1 || continue
			fi
		done
	else 
		log "Installing packages... Only failures will be logged..."
		log "Install string...: installer -pkg \"${mountVolume}/LotsOfPackages.pkg\" -target /"
		log ""
		IFS=$'\n'
        for package in ${packageNames[@]}
		do
        	#log "Installing ${mountVolume}/${package}..."
			installer -pkg "${mountVolume}/${package}" -target / > /dev/null 2>&1
			if [[ $? != 0 ]] ; then
				log "${package} FAILED"
				counter=$((counter+1))
				# The line below is only to trick the loop into continuing if the installation failed.
				fakecommand_thatdoesntexist > /dev/null 2>&1 || continue
			fi
		done
	fi
	unset IFS
	number_of_packages_that_failed_install=$(echo "$counter")
else
	# Run single PKG installation based on passed parameters
	if [[ "$allowUntrusted" == "YES" && ! -z "$applyChoiceChangesXMLFile" ]]; then
		log "Installing Package \"${packageName}\" from mount path \"${mountVolume}\"..."
		log "Install string...: installer -pkg \"${mountVolume}/${packageName}\" -target / -allowUntrusted -applyChoiceChangesXML ${mountVolume}/${applyChoiceChangesXMLFile}"
		log ""
		installer -pkg "${mountVolume}/${packageName}" -target / -allowUntrusted -applyChoiceChangesXML "${mountVolume}"/"${applyChoiceChangesXMLFile}"
		PKGExitCode=($?)
	elif [[ "$allowUntrusted" == "YES" && -z "$applyChoiceChangesXMLFile" ]]; then
		log "Installing Package \"${packageName}\" from mount path \"${mountVolume}\"..."
		log "Install string...: installer -pkg \"${mountVolume}/${packageName}\" -target / -allowUntrusted"
		log ""
		installer -pkg "${mountVolume}/${packageName}" -target / -allowUntrusted
		PKGExitCode=($?)
	elif [[ "$allowUntrusted" != "YES" && ! -z "$applyChoiceChangesXMLFile" ]]; then
		log "Installing Package \"${packageName}\" from mount path \"${mountVolume}\"..."
		log "Install string...: installer -pkg \"${mountVolume}/${packageName}\" -target / -applyChoiceChangesXML ${mountVolume}/${applyChoiceChangesXMLFile}"
		log ""
		installer -pkg "${mountVolume}/${packageName}" -target / -applyChoiceChangesXML "${mountVolume}"/"${applyChoiceChangesXMLFile}"
		PKGExitCode=($?)
	else
		log "Installing Package \"${packageName}\" from mount path \"${mountVolume}\"..."
		log "Install string...: installer -pkg \"${mountVolume}/${packageName}\" -target /"
		log ""
		installer -pkg "${mountVolume}/${packageName}" -target /
		PKGExitCode=($?)
	fi
fi
log ""

# Return / script exit codes
if [[ "$number_of_packages_to_be_installed" -gt 1 && "$forcesuccessflag" = "YES" ]] ; then
    log "Number of PKG failures : $number_of_packages_that_failed_install"
	log "Forced Exit code 0 was passed to JSS"
	log ""
	UnmountDMG
    exit 0
elif [[ "$number_of_packages_to_be_installed" -gt 1 ]] ; then
    log "Number of PKG failures : $number_of_packages_that_failed_install"
	log "Number of PKG failures : $number_of_packages_that_failed_install was passed to JSS"
	log ""
	UnmountDMG
    exit "$number_of_packages_that_failed_install"
elif [[ "$forcesuccessflag" == "YES" ]]; then
    log "PKG exit code was: $PKGExitCode"
	log "Forced Exit code 0 was passed to JSS"
	log ""
	UnmountDMG
	exit 0
else
    log "PKG exit code was...: $PKGExitCode"
    log "Exit code $PKGExitCode was passed to JSS"
    log ""
	UnmountDMG
    exit $PKGExitCode
fi
