#!/bin/sh
####################################################################################################
# NAME: Caffeinate_PreventSleep_v1.0.sh
#
#	Runs caffeinate to prevent machine from sleeping while a policy is running.
#
# DESCRIPTION
#	This script is designed to run in a policy with the before priority. It will prevent a machine
#	from sleeping while a policy is in progress.
#
# HOT TO USE
#	To use this script, please follow the following workflow:
#
#	Step 1: Create a policy
#		2.  Add this script to the policy with the before priority.
#		3.	Optionally add a integer value (number in seconds) into parameter 4 (MaxBlockSleepTime).
#			This will be the length of time caffienate will run before timing out. It will default
#			to 3600 (1 hour)if no value is passed.
#		4.	Add File and Processes into the policy, Execute Command: "killall caffeinate" without
#			quotes.
#
# INFORMATION
# 	All information is logged into the jamf.log and policy log.
####################################################################################################
#
# HISTORY
#
#	Version: 1.0
#
#	- Created by Blake Suggett on August 11, 2020
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
# 
# LOGGING FUNCTION
#
####################################################################################################
ScriptName="Caffeinate_PreventSleep_v1.0.sh"

logFile="/private/var/log/jamf.log"
log () {
	echo $1
	echo $(date "+%a %b %d %H:%M:%S $HOSTNAME ScriptOutput: ") $1 >> $logFile	
}

# Variables used by this script.
MaxBlockSleepTime=""

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
if [ "${4}" != "" ] && [ "${MaxBlockSleepTime}" == "" ]; then
    MaxBlockSleepTime="${4}"
fi

####################################################################################################
# 
# FUNCTIONS
#
####################################################################################################
convertAndPrintSeconds() {  
	local totalSeconds=$1
	local seconds=$((totalSeconds%60))
	local minutes=$((totalSeconds/60%60))
	local hours=$((totalSeconds/60/60%24))
	local days=$((totalSeconds/60/60/24))
	(( $days > 0 )) && printf '%d day/s ' $days
	(( $hours > 0 )) && printf '%d hour/s ' $hours
	(( $minutes > 0 )) && printf '%d minute/s ' $minutes
	(( $days > 0 || $hours > 0 || $minutes > 0 ))
}

####################################################################################################
# 
# VARIABLE VERIFICATION/VALIDATION - DECLEAR TO LOG
#
####################################################################################################
log "$ScriptName"
log ""

if [ -n "${4}" ]; then
	log "MaxBlockSleepTime declared...: ${4}"
	log "Checking its an integer value..."
	if [ $MaxBlockSleepTime -eq $MaxBlockSleepTime 2> /dev/null ]; then
		log "Integer detected"
        log ""
	else
		log "ERROR - not integer"
        log ""
		exit 1
	fi
else
	log "MaxBlockSleepTime not declared...: Defaulting to 3600"
	MaxBlockSleepTime="3600"
fi
if [[ $MaxBlockSleepTime -ge 60 ]]; then
	MaxBlockSleepTime_MinuteHourValue=$(convertAndPrintSeconds $MaxBlockSleepTime)
	log "Block sleep time seconds to minute/s/hours conversion...: $MaxBlockSleepTime_MinuteHourValue"
	log ""
fi
####################################################################################################
# 
# SCRIPT 
#
####################################################################################################

log "Running caffeinate syntax...: caffeinate -i -s -d -t $MaxBlockSleepTime &"
log ""
caffeinate -i -s -d -t $MaxBlockSleepTime &
exit 0