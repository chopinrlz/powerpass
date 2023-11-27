# PowerPass
A cross-platform PowerShell module for secret storage and retrieval on Linux, MacOS, and Windows.
PowerPass supports Windows PowerShell 5 and PowerShell 7.
## Purpose
PowerPass provides an easy to use set of cmdlets for transparently storing and recalling credentials without the need to embed them in your scripts.
When automated scripts require credentials to authenticate with a remote resource, those credentials must be stored alongside the script so they can be recalled for use.
PowerPass allows script designers to store credentials in a secure manner, locked down so that only the login from where they were stored can access them.
If the credentials files are leaked outside the system, they cannot easily be compromised because they are encrypted.
For more information on how to use PowerPass best practices, and for implementation assistance, please review [Incorporating PowerPass into your Scripts](https://chopinrlz.github.io/powerpass/usage).
## Encryption Standards
PowerPass comes in two flavors:
1. 256-bit AES Encryption
2. Windows Data Protection API (Windows PowerShell only)
## Compatibility
1. The AES edition supports PowerShell on Linux, MacOS, and Windows and will run in either Windows PowerShell or PowerShell 7.
2. The Data Protection API edition supports Windows PowerShell as well as KeePass 2 databases, but can only be used on Windows in Windows PowerShell.
3. If you deploy PowerPass from PowerShell 7 it will automatically deploy the AES edition.
4. You can see what flavor of PowerPass you are using by running `(Get-PowerPass).Implementation` which will echo either `AES` or `DPAPI` depending on which module flavor was deployed.
## Documentation
For information about PowerPass and cmdlet reference please browse the [online documentation](https://chopinrlz.github.io/powerpass).
# How It Works
## AES
PowerPass on Linux, MacOS, or Windows in PowerShell 7 can read and write secrets from PowerPass Lockers.
### PowerPass Lockers
A Locker is a 256-bit AES encrypted file which stores your secrets and their metadata in UTF-8 JSON format.
The AES implementation used is native to the operating system on which it runs.
Linux, MacOS, and Windows all provide native 256-bit AES block cipher encryption.
When you first use PowerPass, the module will generate a key for you.
The Locker is stored in your home directory while they key is stored in your application data directory.
You can export your locker and key to save a backup copy elsewhere.
You can also rotate your locker key automatically.
## Data Protection API
PowerPass on Windows PowerShell supports secrets from these two sources:
1. KeePass 2 databases
2. PowerPass lockers
### KeePass 2 Databases
KeePass, a .NET Framework application built by Dominik Reichl <dominik.reichl@t-online.de>, is a popular application used for storing and retrieving secrets (like login credentials) from encrypted databases that the KeePass application itself creates.
PowerPass builds on top of the core KeePass library to provide programmatic access to KeePass database secrets through the use of Windows PowerShell.
### PowerPass Lockers
A PowerPass Locker is an encrypted file created by PowerPass to store and retrieve secrets which can only be accessed by your user account.
After you deploy PowerPass, you can immediately read and write secrets from your Locker.
PowerPass Lockers rely on the encryption implementation found in the Windows Data Protection API.
To increase the difficulty of attackers brute-force decrypting your Locker, the Locker is salted with a random key which is in turn salted by the PowerPass random key generated at deployment time.
The Locker is stored in your Application Data folder along with the encrypted salt file.
Meanwhile, there is a secondary encrypted salt file stored in the module's folder.
You can export your locker and key to save a backup copy elsewhere.
You can also rotate your locker salts automatically, but the locker key is built-in to your Windows profile.
All three files are encrypted with the Data Protection API.
Your locker and locker salt are encrypted with your profile key while the module salt is encrypted with the machine key.
# Deployment and Usage
PowerPass comes with a deployment script called `Deploy-PowerPass.ps1` which will install the module for you.
For detailed deployment and usage instructions please see [Deployment and Usage](https://chopinrlz.github.io/powerpass/deployment) in the online documentation.