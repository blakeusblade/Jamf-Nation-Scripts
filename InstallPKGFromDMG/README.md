# jamfs installPKGsFromDMG

## All versions of the installPKGfromDMG scripts.

### installPKGfromDMG_v1.0.sh
* This is the original installPKGfromDMG script.
	Capabilities - 
		Passed parameter 4 = DMG filename

### installPKGfromDMG_v2.0.sh
* This has refined code to allow greater flexibilty when dealing with expected failures.
	- Capabilities 
		* Passed parameter 4 = DMG filename
		* Passed parameter 5 = forcesuccessflag
			When this parameter is used by supplying "YES" in uppercase without quotes will output the PKG exit code to the log and pass an exit of 0 to the policy. This is useful in certain circumstances if you want to run an a PKG (eg and PKG uninstaller) then an installer PKG. You might want to ignore the first uninstaller PKG's exit code.
	- Improvements
		* Passed parameters passed into the logs allowing easier troubleshooting.
		* PKG exit codes are pass into the logs seperately from script exit code.

### installPKGsfromDMG_v5.0.sh
* This has additional and refined code to allow greater flexibilty.
	- Capabilities
		* Passed parameter 4 = DMG filename
		* Passed parameter 5 = forcesuccessflag
		* Passed parameter 6 = useinstallerapp
			When this parameter is used by supplying "YES" in uppercase without quotes, the script doesn't use the default jamf binary to perform the PKG installation. Some PKG's or MPKG's (few and far between) don't like installing using the jamf binary and will exit with an error code. This will force the installer binary to perform the installation. When using this, the PKG installation is run from the mounted DMG. Whereas the default behavior where the jamf binary is used it automatically copies the PKG from the DMG into the Downloads or Waiting Room and runs the PKG from there.
		* Passed parameter 7 = allowUntrusted
			Dependancy = Parameter 6 = "YES" in uppercase without quotes
			When this parameter is used by supplying "YES" in uppercase without quotes, it allows the installation of PKG's that have expired installer certificates. This is useful in an event whereby (eg Printer vendor no longer exists or isn't mainting printer drivers).
		* Passed parameter 8 = applyChoiceChangesXMLFile
			Dependancy = Parameter 6 = "YES" in uppercase without quotes
			When this parameter is used by supplying parameter 8 with an .xml file that exists inside your DMG (next to your PKG) it allows the customisation of PKG installations. This is useful if the PKG has many installation options or components that you may or may not want to have installed. Passing INSERTFILENAME.xml allows the installation to install only the options and or components you desire.
		* Passed parameter 9 = multipkgs
			When this parameter is used by supplying "YES" in uppercase without quotes will allow the script to install every PKG or MPKG within a single DMG. This is useful if one wants to install many PKGs from a single DMG wrapper. This could be many single adobe installers or Apple's Logic or GarageBand sample sound library installers. The number of m/pkgs installers to be run will be logged, followed by any packages that fail and the amount of failures will be passed to the exit code. If used in conjunction with parameter 5(forcesuccessflag) the same information is passed however a forced exit code of zero will be passed to the JSS.
	- Improvments
		* Elements of the script made into functions decreasing script length and complexity
		* Additional logging to better aid in troubleshooting

	Uploaded to jamf nation by myself
	https://www.jamf.com/jamf-nation/third-party-products/files/1048/installpkgsfromdmg

This Jamf pro scripts is constantly in revision for improvements.
