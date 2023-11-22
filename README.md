# PowerPass
A cross-platform PowerShell module for secret storage and retrieval on Linux, MacOS, and Windows. PowerPass supports Windows PowerShell 5 and PowerShell 7. PowerPass comes in two flavors:
1. 256-bit AES Encryption
2. Windows Data Protection API (Windows PowerShell only)
## Purpose
PowerPass provides an easy to use set of cmdlets for transparently storing and recalling credentials without the need to embed them in your scripts.
When automated scripts require credentials to authenticate with a remote resource, those credentials must be stored alongside the script so they can be recalled for use.
PowerPass allows script designers to store credentials in a secure manner, locked down so that only the login from where they were stored can access them.
If the credentials files are leaked outside the system, they cannot easily be compromised because they are encrypted.
For more information on how to use PowerPass best practices, and for implementation assistance, please review [Incorporating PowerPass into your Scripts](https://chopinrlz.github.io/powerpass/usage).
## Compatibility
1. The AES flavor supports PowerShell on Linux, MacOS, and Windows and will run in either Windows PowerShell or PowerShell 7.
2. The Data Protection API flavor supports Windows PowerShell as well as KeePass 2 databases, but can only be used on Windows in Windows PowerShell.
3. If you deploy PowerPass from PowerShell 7 it will automatically deploy the AES edition.
4. You can see what flavor of PowerPass you are using by running `(Get-PowerPass).Implementation` which will echo either `AES` or `DPAPI` depending on which module flavor was deployed.
# How It Works
## AES
PowerPass on Linux, MacOS, or Windows in PowerShell 7 can read and write secrets from PowerPass Lockers.
A Locker is a 256-bit AES encrypted file which stores your secrets and metadata in JSON format.
When you first use PowerPass, the module will generate a key for you.
The Locker is stored in your home directory while they key is stored in your application data directory.
You can export your locker and key to save a backup copy elsewhere.
You can also rotate your locker key automatically.
## Data Protection API
PowerPass on Windows PowerShell supports secrets from these two sources:
1. KeePass 2 databases
2. PowerPass lockers
## KeePass 2
KeePass, a .NET Framework application built by Dominik Reichl <dominik.reichl@t-online.de>, is a popular application used for storing and retrieving secrets (like login credentials) from encrypted databases that the KeePass application itself creates.
PowerPass builds on top of the core KeePass library to provide programmatic access to KeePass database secrets through the use of Windows PowerShell.
## PowerPass Lockers
A PowerPass Locker is an encrypted file created by PowerPass to store and retrieve secrets which can only be accessed by your user account.
After you deploy PowerPass, you can immediately read and write secrets from your Locker, which is stored in your user profile's Application Data directory.
PowerPass Lockers rely on the encryption implementation found in the Windows Data Protection API.
To increase the difficulty of attackers brute-force decrypting your Locker, the Locker is salted with a random key which is in turn salted by the PowerPass random key generated at deployment time.
The salt for your Locker is encrypted using your Windows user account.
The salt for the PowerPass deployment is encrypted using the machine key.
# Documentation
For information about PowerPass and cmdlet reference please browse the [online documentation](https://chopinrlz.github.io/powerpass).
# Deployment
PowerPass comes with a deployment script which will compile the KeePassLib source code, generate a PowerPass module salt (for salting Locker keys), and deploy the module. You can deploy the module to your user profile home directory for yourself, or you can deploy the module for all users (which requires administrative permissions).
## Step 1: Clone the Repository
Clone this repository to a **writeable** folder on your local machine. You must run the deployment script with write permissions to the local folder in order to compile KeePassLib and generate a salt file.
## Step 2: Run Deploy-PowerPass.ps1
Open your preferred PowerShell environment and run `.\Deploy-PowerPass.ps1` to compile and deploy this module.
If you are using Windows PowerShell you will be prompted to install either the AES or DP API with KeePass support variant.
## Step 3: Verify the Deployment
You can test the deployment with these cmdlets:
1. Open-PowerPassTestDatabase (DP API only)
2. Read-PowerPassSecret

Running `Open-PowerPassTestDatabase` (DP API only) will load the KeePass test database bundled with the repository confirming that KeePassLib compiled successfully and can read KeePass databases.
Running `Read-PowerPassSecret` will initialize your PowerPass Locker with a default secret and output it to the pipeline.
This will confirm the Locker functionality of PowerPass is working properly.
For details on prerequisites for each implementation, please see the [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) page.
# Usage
## KeePass Databases
To open a KeePass database use the `Open-PowerPassDatabase` cmdlet.
Pipe or pass the output to `Get-PowerPassSecret` to fetch secrets from the KeePass database.
## PowerPass Locker
To read a secret from your PowerPass Locker use the `Read-PowerPassSecret` cmdlet.
To write a secret into your PowerPass Locker use the `Write-PowerPassSecret` cmdlet.
## Storing KeePass Database Passwords
If you are opening KeePass databases which use master passwords, you can store these passwords in your PowerPass Locker to keep them secure.
# Cmdlet Reference
1. For the AES implementation, please see [PowerPass AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref)
1. For the DP API implementation, please see [PowerPass DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref)
# Additional Information
## About KeePassLib
PowerPass comes bundled with the KeePassLib 2.55 source code which is copyright 2003-2023 Dominik Reichl <dominik.reichl@t-online.de> and is licensed under the GNU Public License 2.0. A copy of this license is included in the LICENSE file in this repository. KeePassLib has not been modified from its release version. You can use PowerPass with KeePassLib 2.55 or with your own version of KeePassLib.
## Test Database Password
You can alter the KeePass test database if you like. The master password to the test database TestDatabase.kdbx is "12345" without the quotation marks. The test database is stored in the module deployment directory.
## Unit Testing
You can run all the unit tests developed for PowerPass by running the `Test-PowerPass.ps1` script in the `PowerPassTests` directory after deploying the module. This script runs a series of unit tests against PowerPass to ensure that all functionality works as designed.