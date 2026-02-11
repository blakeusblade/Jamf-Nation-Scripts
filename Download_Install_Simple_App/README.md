# Download Install Simple .app in a DMG from a URL Project

## All versions of the Download_Install_Simple_App scripts.

### Download_Install_Simple_App_2.0.sh
* This is the original Download_Install_Simple_App_2.0 script.
	- Capabilities 
		* Passed parameter 4 = Download URL
			- This is a mandatory feild requiring you to supply a HTTPS url to a DMG to download and install the .app within into the applications directory.
		
			i.e  
			https://download.mozilla.org/?product=firefox-latest-ssl&os=osx&lang=en-US  
			for Mozilla Firefox (not ESR version)
			
			https://dl.google.com/chrome/mac/universal/stable/gcea/googlechrome.dmg  
			for Google Chrome (Enterprise version)
			
   		* Passed parameter 5 = removeEAs
			- When this parameter is used by supplying "YES" in uppercase without quotes will recursively remove extended attributes from the .app once installed 

Jamf policy log output below

<img width="732" height="641" alt="Screenshot 2026-02-11 at 12 43 52 pm" src="https://github.com/user-attachments/assets/b5b4257f-571d-4e43-bb7c-b4dbca755d6f" />

This Jamf pro script is constantly in revision for improvements.
