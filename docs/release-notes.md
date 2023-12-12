The latest release of PowerPass version 1.4.2 updates the import and export functionality. It has been tested on Linux and Windows on PowerShell 7 and Windows PowerShell.
# Changelog
### Importing and Exporting Lockers
On both the AES edition and Data Protection API edition of PowerPass, lockers are now exported using AES encryption to a single file. Keys and salts are not exported, nor are they replaced or rotated on import. Rotating keys and salts can be done using the built-in `Update-PowerPassKey` or `Update-PowerPassSalt` cmdlets at any time.
### Importing and Exporting Across Editions
Due to the changes in the way locker exporting and importing works, you can now export a locker from the AES edition and import it into the Data Protection API edition, or vice versa, across PowerShell versions or operating systems. This greatly increases the flexibility and portability of lockers from one system to another. It also facilitates the distribution of lockers across multiple systems.
### Passwords for Importing and Exporting
You are no longer able to use the `-Password` parameter with the import and export cmdlets. Instead, you will be prompted to enter a password (which will be masked on input) when you invoke the export or import cmdlet. This means that importing and exporting cannot be automated, but it also prevents passwords from being displayed on the console or inadvertently saved within a script.
# Bug Fixes
### MacOS App Data Folder Detected Incorrectly
On previous versions of PowerPass, the MacOS user's app data folder was detected incorrectly, causing the module to fail on start. This has been corrected in version 1.4.2 with the local app data folder being used in lieu of the generic app data folder which Linux uses.
# Deployment
To install:
1. Clone the repo, download the release, or download the source code for this release
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder)
# File Hashes
| Release                 | SHA256 Hash                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| PowerPass-1.4.2.tar.gz  | 1D20D82A10DEE6764752434E898D028656FA3B61D6965C01366B695B088C63CC |
| PowerPass-1.4.2.zip     | FCEB607102914AB63FB8E674D1811B4CBA9CAC30802226249511EBBA199C35E5 |