# Download and then install a PKG from a URL Project

## All versions of the installPKGfromDMG scripts.

### Download_Install_PKG_v1.0.sh
* This is the original installPKGfromDMG script.
	- Capabilities 
		* Passed parameter 4 = DMG filename

### installPKGfromDMG_v2.0.sh
* This has refined code to allow greater flexibilty when dealing with expected failures.
	- Capabilities 
		* Passed parameter 4 = DMG filename
		* Passed parameter 5 = forcesuccessflag
			- When this parameter is used by supplying "YES" in uppercase without quotes will output the PKG exit code to the log and pass an exit of 0 to the policy. This is useful in certain circumstances if you want to run an a PKG (eg and PKG uninstaller) then an installer PKG. You might want to ignore the first uninstaller PKG's exit code.
	- Improvements
		* Passed parameters passed into the logs allowing easier troubleshooting.
		* PKG exit codes are pass into the logs seperately from script exit code.

### installPKGsfromDMG_v5.0.sh
* This has additional and refined code to allow greater flexibilty.
	- Capabilities
		* Passed parameter 4 = DMG filename
		* Passed parameter 5 = forcesuccessflag
		* Passed parameter 6 = useinstallerapp
			- When this parameter is used by supplying "YES" in uppercase without quotes, the script doesn't use the default jamf binary to perform the PKG installation. Some PKG's or MPKG's (few and far between) don't like installing using the jamf binary and will exit with an error code. This will force the installer binary to perform the installation. When using this, the PKG installation is run from the mounted DMG. Whereas the default behavior where the jamf binary is used it automatically copies the PKG from the DMG into the Downloads or Waiting Room and runs the PKG from there.
		* Passed parameter 7 = allowUntrusted
			- Dependancy = Parameter 6 = "YES" in uppercase without quotes
			- When this parameter is used by supplying "YES" in uppercase without quotes, it allows the installation of PKG's that have expired installer certificates. This is useful in an event whereby (eg Printer vendor no longer exists or isn't mainting printer drivers).
		* Passed parameter 8 = applyChoiceChangesXMLFile
			- Dependancy = Parameter 6 = "YES" in uppercase without quotes
			- When this parameter is used by supplying parameter 8 with an .xml file that exists inside your DMG (next to your PKG) it allows the customisation of PKG installations. This is useful if the PKG has many installation options or components that you may or may not want to have installed. Passing INSERTFILENAME.xml allows the installation to install only the options and or components you desire.
		* Passed parameter 9 = multipkgs
			- When this parameter is used by supplying "YES" in uppercase without quotes will allow the script to install every PKG or MPKG within a single DMG. This is useful if one wants to install many PKGs from a single DMG wrapper. This could be many single adobe installers or Apple's Logic or GarageBand sample sound library installers. The number of m/pkgs installers to be run will be logged, followed by any packages that fail and the amount of failures will be passed to the exit code. If used in conjunction with parameter 5(forcesuccessflag) the same information is passed however a forced exit code of zero will be passed to the JSS.
	- Improvments
		* Elements of the script made into functions decreasing script length and complexity
		* Additional logging to better aid in troubleshooting
		* Adding capability to have spaces in the DMG and PKG filenames

	Uploaded to jamf nation by myself
	https://www.jamf.com/jamf-nation/third-party-products/files/1048/installpkgsfromdmg

It should be noted that the default behaviour is to use the jamf binary (ie paramater 6 NOT in use) which copies the PKG to be installed into the /Library/Application Support/JAMF/Downloads directory and runs the PKG from there. When using paramater 6 (ie supplying "YES" without quotes to paramater 6) the installer binary is used and the PKG installation runs from the mounted DMG.

### installPKGsfromDMG_v9.0.sh
* This update is to address default behaviour and refined code to allow greater flexibilty.
	- Capabilities
		* Passed parameter 4 = Mandatory - Fullpath to DMG or DMG Filename including extensions suffix (no \ character escape for spaces in path or filenames)
  			- Previously one could only define a DMG filename which the script would expect the DMG file to be cached to the following path "/Library/Application Support/JAMF/Waiting\ Room" from a jamf policy. This has been updated to allow greater flexibility in allowing a full path to any DMG file on disk. If providing the paramater a simple DMG filename, the script expects it to be in the JAMF/Waiting\ Room directory. If providing a full path to a DMG, the script will use that DMG defined with the custom path. It will outline if using the default path or a custom path in the logs. Additionally, any DMG defined inside as temp directories i.e /private/tmp , /private/var/tmp , /tmp/ , or the above mentioned JAMF/Waiting\ Room directory, the script will remove the DMG file from the disk upon unmounting. Any other directory the DMG file will NOT be removed from the disk. This allows a DMG to remain on disk if needed byu simply defining a custom path to a DMG. Existing policies passing this parameter won't be affected if upgrading script syntax.
       
	   Log output examples
	   
       		Variable "dmgName" value is set to: "Apple_xCode_26.2_for_macOS_15.6+.dmg"
			Verifying default "DMG path"...: valid

       		Variable "dmgName" value is set to: "/tmp/Apple_xCode_26.2_for_macOS_15.6+.dmg"
			Verifying custom "DMG path"...: valid

     		Variable "dmgName" value is set to: "/private/var/Apple_xCode_26.2_for_macOS_15.6+.dmg"
			Verifying custom "DMG path"...: invalid
			
		* Passed parameter 6 = Optional useinstallerapp, eg YES (case sensitive) - deprecated/removed/unassigned
  			- This parameters forced using the installer binary to perform installation. This is now the scripts default behaviour. This parameter has been removed. Existing policies passing this parameter won't be affected if upgrading script syntax.
       
	   Log output examples

			Installing Package "Apple_xCode_26.2_for_macOS_15.6+.pkg" from mount path "/Volumnes/Apple_xCode_26.2_for_macOS_15.6+
			Install string...: installer -pkg /Volumnes/Apple_xCode_26.2_for_macOS_15.6+/Apple_xCode_26.2_for_macOS_15.6+.pkg -target / 

			PKG exit code was: 1
			Forced Exit code 0 was passed to JSS

			PKG exit code was: 0
			Exit code 0 was passed to JSS

			Installing packages, Only failures will be logged..."
			Install string...: installer -pkg /Volumnes/DMGVolumeName/LotsOfPackages.pkgs -target /

		* Passed parameter 9 = Optional MultiPKGs, eg YES (case sensitive) - deprecated/removed/unassigned
  			- This parameter forced the script to loop through all PKG's within the DMG, installing all of them and logging the filename of failed PKGs. The number of failures would be passed to the JSS/Jamf Pro. This is now default behaviour. The script will automatically scan the mounted DMG and detect if mutiple PKGs are present. Additionally, functionality has been included to allow certain PKG's to be installed and not others. ie. Parent.pkg installation calls child.pkg resulting in a successful installation. In certain cases (vendor pkg installers) if child.pkg is called, it might fail because its not being called by its parent.pkg. To acheive this with the script, before creating your DMG, in terminal use chflags -hidden /path/some/child.pkg. This will flag child.pkg within the DMG to be hidden and so the script will not run child.pkg independently. Parent.pkg will be run by the script and not child.pkg. Existing policies passing this parameter won't be affected if upgrading script syntax.
		
		Log output examples

		  	ERROR - Number of packages to be installed...: Greater than 1 and applyChoiceChangesXMLFile is declared
			
		  	Number of packages to be installed...: 50
			
		  	Installing packages... Only failures will be logged...
		  	Install string...: installer -pkg /Volumnes/DMGVolumeName/LotsOfPackages.pkgs -target /
		  	
		  	Apple_Numbers_3.2.1.pkg FAILED
		  	Number of PKG failures : 1
		  	Forced Exit code 0 was passed to JSS

		  	Number of PKG failures : 0
		  	Exit code 0 was passed to JSS
			
			
- Improvments
	* Elements of the script made into functions decreasing script length and complexity
	* Additional logging to better aid in troubleshooting

This Jamf pro script is constantly in revision for improvements.
