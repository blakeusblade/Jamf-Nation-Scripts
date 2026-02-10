# Download and then install a PKG from a URL Project

## All versions of the installPKGfromDMG scripts.

### Download_Install_PKG_v1.0.sh
* This is the original Download_Install_PKG script.
	- Capabilities 
		* Passed parameter 4 = Download URL
			- This is a mandatory feild requiring you to supply a HTTPS url to a PKG to download and install
     	* Passed parameter 5 = forcesuccessflag
			- When this parameter is used by supplying "YES" in uppercase without quotes will output the PKG exit code to the log and pass an exit of 0 to the policy. This is useful in certain circumstances if you expect a PKG failure

This Jamf pro script is constantly in revision for improvements.
