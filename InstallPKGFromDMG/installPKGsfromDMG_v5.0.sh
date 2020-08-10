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
#	Version: 5.0
#
#	- Created by Nick Amundsen on July 22, 2011
#   - Modified by Blake Suggett on March 2, 2020
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
dmgName=""
multiPKGs="" # Optional - eg YES in uppercase. Allows the script to loop through PKGs or MPKGs running installations
forcesuccessflag="" # Optional - eg YES in uppercase. Allows the script to force an exit code of zero to JAMF Pro. The PKG exit code will be recorded in policy logs  
useinstallerapp="" # Optional - eg YES in uppercase. Forces the script to use installer binary rather than the jamf binary.
allowUntrusted="" # Optional - eg YES in uppercase. Allows the installation of PKGs or MPKGs that have expired certificates. Dependant on variable useinstallerapp
applyChoiceChangesXMLFile="" # Optional - eg mychoicechanges.xml. This allows one to pass a xml answer file to a PKG for custom installations. Dependant on variable useinstallerapp

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
if [ "${6}" != "" ] && [ "${useinstallerapp}" == "" ]; then
    useinstallerapp="${6}"
fi
if [ "${7}" != "" ] && [ "${allowUntrusted}" == "" ]; then
    allowUntrusted="${7}"
fi
if [ "${8}" != "" ] && [ "${applyChoiceChangesXMLFile}" == "" ]; then
    applyChoiceChangesXMLFile="${8}"
fi
if [ "${9}" != "" ] && [ "${multiPKGs}" == "" ]; then
    multiPKGs="${9}"
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

log "installPKGsfromDMG.sh"
log ""

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

# Verify Variables
verifyVariable dmgName
verifyVariableYESorNo forcesuccessflag
verifyVariableYESorNo useinstallerapp
verifyVariableYESorNo allowUntrusted
verifyVariableYESorNo multiPKGs

if [[ -z "$applyChoiceChangesXMLFile" ]]; then
	log "Variable \"applyChoiceChangesXMLFile\" not declared..."
else
	log "Variable \"applyChoiceChangesXMLFile\" declared...: ${applyChoiceChangesXMLFile}"
fi
if [[ "$multiPKGs" == "YES" && ! -z "$applyChoiceChangesXMLFile" ]]; then
	log ""
	log "ERROR - Parameter 9 (multiPKGs) and Parameter 8 (applyChoiceChangesXMLFile) can't be used in conjunction with each other"
	exit 1
fi
if [[ "$useinstallerapp" != "YES" && "$allowUntrusted" = "YES" || "$useinstallerapp" != "YES" && ! -z "$applyChoiceChangesXMLFile" ]]; then
	log ""
	log "ERROR - Parameters 7 (allowUntrusted), and 8 (applyChoiceChangesXMLFile) can't be used without Parameters 6 (useinstallerapp)"
	exit 1
fi

# Attempt to remove any existing mounts
UnmountDMGNameOnly=`echo "${dmgName}" | sed 's/.dmg*//'`
if [[ -d /Volumes/"${UnmountDMGNameOnly}" ]] ; then
	log ""
    log "Found an existing mounted DMG, unmounting..."
    hdiutil detach /Volumes/"${UnmountDMGNameOnly}" -force
fi
if [[ -f /Library/Application\ Support/JAMF/Waiting\ Room/"${dmgName}".shadow ]] ; then
    log "Found an existing shadow file, removing..."
    rm -f /Library/Application\ Support/JAMF/Waiting\ Room/"${dmgName}".shadow
fi

MountDMG () {
# Mount the DMG
log "Mounting the DMG \"${dmgName}\""
mountResult=`/usr/bin/hdiutil mount -private -noautoopen -noverify /Library/Application\ Support/JAMF/Waiting\ Room/"${dmgName}" -shadow`
if [[ $? != 0 ]] ; then
	log "There was an error mounting the DMG. mountResult hdiutil exit code: $?"
	exit 1
else
	mountVolume=`echo "${mountResult}" | grep Volumes | awk -F " " '{$1=$2=""; print $0}' | sed 's/^ *//g'`
	# mountVolumeExitCode=($?)
	if [[ $? != 0 ]] ; then
		log "There was an error mounting the DMG. mountVolume grep volume exit code: $?"
		exit 1
	fi
	mountDevice=`echo "${mountResult}" | grep disk | head -1 | awk '{print $1}'`
	# mountDeviceExitCode=($?)
	if [[ $? != 0 ]] ; then
		log "There was an error mounting the DMG. mountDevice grep disk exit code: $?"
		exit 1
	fi
fi
log "DMG mounted successfully as volume \"${mountVolume}\" on device \"${mountDevice}\"."
log ""
}
UnmountDMG () {
	# Unmount the DMG
    log "Unmounting disk ${mountDevice}..."
    hdiutil detach "${mountDevice}" -force
    UnmountDMGExitCode=($?)
    # If unmount failed attempt unmount using the volumes directory path
    if [ $UnmountDMGExitCode != 0 ] ; then
        log "Unable to unmount using native mountDevice... Attempting volumes unmount..."
        hdiutil detach /Volumes/"${UnmountDMGNameOnly}" -force
        UnmountDMGExitCode=($?)
    fi
    if [ $UnmountDMGExitCode == 0 ] ; then
        log "Successfully unmounted"
    fi
    # Delete the DMG and the shadow file
    /bin/rm /Library/Application\ Support/JAMF/Waiting\ Room/"${dmgName}"
	/bin/rm -f /Library/Application\ Support/JAMF/Waiting\ Room/"${dmgName}".shadow
}
GetPackages() {
	if [[ "$multiPKGs" == "YES" ]]; then
		packageNames=`ls "${mountVolume}" | grep "pkg"`
		if [[ -z "$packageNames" ]] ; then
			log "ERROR - No pkgs or mpkgs were found."
			UnmountDMG
			Exit 1
		fi
	else
		packageName=`ls "${mountVolume}" | grep "pkg" | head -1`
		if [[ -z "$packageName" ]] ; then
			log "ERROR - No pkgs or mpkgs were found."
			UnmountDMG
			Exit 1
		fi
	fi
}
log ""

####################################################################################################
# 
# SCRIPT CONTENTS - DO NOT MODIFY BELOW THIS LINE
#
####################################################################################################
MountDMG

# Run multiple PKG installations from a DMG if multiPKGs = YES
if [[ "$multiPKGs" == "YES" ]]; then
	GetPackages
	# Announce number of packages to be installed
	numberofpackagestobeinstalled=`echo "$packageNames" | wc -l | awk '{print $1}'`
	log "Number of packages to be installed...: $numberofpackagestobeinstalled"
	log ""
	counter=0
	if [[ "$useinstallerapp" == "YES" && "$allowUntrusted" == "YES" ]]; then
		log "Installing packages using installer binary, allowing untrusted PKGs..."
		log "Install string...: installer -pkg \"${mountVolume}/PackageFileName.pkg\" -target / -allowUntrusted"
		log ""
		IFS=$'\n'
		for package in ${packageNames}
		do
			installer -pkg "${mountVolume}"/$package -target / -allowUntrusted > /dev/null 2>&1
			if [[ $? != 0 ]] ; then
				log "${package} FAILED"
				counter=$((counter+1))
				# The line below is only to trick the loop into continuing if the installation failed.
				fakecommand_thatdoesntexist > /dev/null 2>&1 || continue
			fi
		done
	elif [[ "$useinstallerapp" == "YES" ]]; then
		log "Installing packages using installer binary..."
		log "Install string...: installer -pkg \"${mountVolume}/PackageFileName.pkg\" -target /"
		log ""
		IFS=$'\n'
		for package in ${packageNames}
		do
			installer -pkg "${mountVolume}"/$package -target / > /dev/null 2>&1
			if [[ $? != 0 ]] ; then
				log "${package} FAILED"
				counter=$((counter+1))
				# The line below is only to trick the loop into continuing if the installation failed.
				fakecommand_thatdoesntexist > /dev/null 2>&1 || continue
			fi
		done
	elif [[ "$useinstallerapp" != "YES" ]]; then
		log "Installing packages using default jamf binary..."
		log "Install string...: jamf install -path \"${mountVolume}/\" -package PackageFileName.pkg -target /"
		log ""
		IFS=$'\n'
		for package in ${packageNames}
		do
			/usr/local/jamf/bin/jamf install -path "${mountVolume}"/ -package $package -target / > /dev/null 2>&1
			if [[ $? != 0 ]] ; then
				log "${package} FAILED"
				counter=$((counter+1))
				# The line below is only to trick the loop into continuing if the installation failed.
				fakecommand_thatdoesntexist > /dev/null 2>&1 || continue
			fi
		done
	fi
	unset IFS
# Run a single PKG installation from a DMD if multiPKGs = No (default value)
else
	GetPackages
	# Run installation based on passed parameters
	if [[ "$useinstallerapp" == "YES" && "$allowUntrusted" == "YES" && ! -z "$applyChoiceChangesXMLFile" ]]; then
		log "Installing Package \"${packageName}\" from mount path \"${mountVolume}\"..."
		log "Install string...: installer -pkg \"${mountVolume}/${packageName}\" -target / -allowUntrusted -applyChoiceChangesXML ${mountVolume}/${applyChoiceChangesXMLFile}"
		installer -pkg "${mountVolume}/${packageName}" -target / -allowUntrusted -applyChoiceChangesXML "${mountVolume}"/"${applyChoiceChangesXMLFile}"
		PKGExitCode=($?)
	elif [[ "$useinstallerapp" == "YES" && "$allowUntrusted" == "YES" && -z "$applyChoiceChangesXMLFile" ]]; then
		log "Installing Package \"${packageName}\" from mount path \"${mountVolume}\"..."
		log "Install string...: installer -pkg \"${mountVolume}/${packageName}\" -target / -allowUntrusted"
		installer -pkg "${mountVolume}/${packageName}" -target / -allowUntrusted
		PKGExitCode=($?)
	elif [[ "$useinstallerapp" == "YES" && "$allowUntrusted" != "YES" && ! -z "$applyChoiceChangesXMLFile" ]]; then
		log "Installing Package \"${packageName}\" from mount path \"${mountVolume}\"..."
		log "Install string...: installer -pkg \"${mountVolume}/${packageName}\" -target / -applyChoiceChangesXML ${mountVolume}/${applyChoiceChangesXMLFile}"
		installer -pkg "${mountVolume}/${packageName}" -target / -applyChoiceChangesXML "${mountVolume}"/"${applyChoiceChangesXMLFile}"
		PKGExitCode=($?)
	elif [[ "$useinstallerapp" == "YES" ]]; then
		log "Installing Package \"${packageName}\" from mount path \"${mountVolume}\"..."
		log "Install string...: installer -pkg \"${mountVolume}/${packageName}\" -target /"
		installer -pkg "${mountVolume}/${packageName}" -target /
		PKGExitCode=($?)
	elif [[ "$useinstallerapp" != "YES" ]]; then
		log "Installing Package \"${packageName}\" from mount path \"${mountVolume}\"..."
		log "Install string...: jamf install -path \"${mountVolume}\" -package \"${packageName}\""
		/usr/local/jamf/bin/jamf install -path "${mountVolume}" -package "${packageName}"
		PKGExitCode=($?)
	fi
fi
log ""

# Return / script exit codes
if [[ "$multiPKGs" == "YES" && "$forcesuccessflag" = "YES" ]] ; then
    log "Number of PKG failures : $counter"
	log "Forced Exit code 0 was passed to JSS"
	UnmountDMG
    exit 0
elif [[ "$multiPKGs" == "YES" ]] ; then
    log "Number of PKG failures : $counter"
	log "Number of PKG failures : $counter was passed to JSS"
	UnmountDMG
    exit $counter
elif [[ "$forcesuccessflag" == "YES" ]]; then
    log "PKG exit code was: $PKGExitCode"
	log "Forced Exit code 0 was passed to JSS"
	UnmountDMG
	exit 0
else
    log "PKG exit code was...: $PKGExitCode"
    log "Exit code $PKGExitCode was passed to JSS"
	UnmountDMG
    exit $PKGExitCode
fi