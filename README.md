# PowerPass
A PowerShell module for secret storage and retrieval.
## About PowerPass
PowerPass supports secrets from two sources:
1. KeePass 2 databases
2. PowerPass lockers
### KeePass 2
KeePass, a .NET Framework application built by Dominik Reichl <dominik.reichl@t-online.de>, is a popular application used for storing and retrieving secrets (like login credentials) from encrypted databases that the KeePass application itself creates. PowerPass builds on top of the core KeePass library to provide programmatic access to KeePass database secrets through the use of Windows PowerShell.
### PowerPass Lockers
A PowerPass Locker is an encrypted file created by PowerPass to store and retrieve secrets which can only be accessed by your user account. After you deploy PowerPass, you can immediately write and read secrets into your Locker, which is stored in your user profile's Application Data directory. PowerPass Lockers rely on the encryption implementation found in the Windows Data Protection API. To increase the difficulty of attackers brute-force decrypting your Locker, the Locker is salted with a random key which is in turn salted by the PowerPass random key generated at deployment time. The salt for your Locker is encrypted using your Windows user account. The salt for the PowerPass deployment is encrypted using the machine key.
## Documentation
For information about PowerPass and cmdlet reference please browse the [online documentation](https://chopinrlz.github.io/powerpass).
# Prerequisites
## Windows PowerShell 5,1
PowerPass is designed for use with Windows PowerShell 5.1, although there is a plan to upgrade PowerPass to work cross-platform in the near future.
## .NET Framework 4.8.1
PowerPass is designed to work with the latest version of the .NET Framework 4.8.1.
## C# Compiler
PowerPass is compiled from source at deployment time. You must have the C# compiler installed with the .NET Framework. It is typically included by default.
# Deployment
PowerPass comes with a deployment script which will compile the KeePassLib source code, generate a PowerPass module salt (for salting Locker keys), and deploy the module. You can deploy the module to your user profile home directory for yourself, or you can deploy the module for all users (which requires administrative permissions).
## Step 1: Clone the Repository
Clone this repository to a **writeable** folder on your local machine. You must run the deployment script with write permissions to the local folder in order to compile KeePassLib and generate a salt file.
## Step 2: Run Deploy-PowerPass.ps1
Open Windows PowerShell 5.1 and run `.\Deploy-PowerPass.ps1` to compile and deploy this module. This script has two parameters: `Target` and `Path`.
### Parameter: Target
The `Target` parameter can have one of two values: `CurrentUser` or `System`.
* If you specify `CurrentUser` the module will be installed for you and deployed to your WindowsPowerShell/Modules folder in your user profile directory.
* If you specify `System` the module will be installed for all users and deployed to the Program Files directory which will require administrative privileges.

You do not need to specify the `Target` parameter. It will default to `CurrentUser`.
### Parameter: Path
If you specify the `Path` parameter, the `Target` parameter is ignored and the module is deployed to the path on disk you specify here. This directory MUST exist.
## Step 3: Verify the Deployment
To ensure that you have deployed PowerPass succssfully, run each of these two cmdlets from Windows PowerShell:
1. Open-PowerPassTestDatabase
2. Read-PowerPassSecret

Running `Open-PowerPassTestDatabase` will load the KeePass test database bundled with the repository confirming that KeePassLib compiled successfully and can read KeePass databases.
Running `Read-PowerPassSecret` will initialize your PowerPass Locker with a default secret and output it to the pipeline. This will confirm the Locker functionality of PowerPass is working propertly.
# Usage
## KeePass Databases
To open a KeePass database use the `Open-PowerPassDatabase` cmdlet. Pipe or pass the output to `Get-PowerPassSecret` to fetch secrets from the KeePass database.
## PowerPass Locker
To read a secret from your PowerPass Locker use the `Read-PowerPassSecret` cmdlet. To write a secret into your PowerPass Locker use the `Write-PowerPassSecret` cmdlet.
## Storing KeePass Database Passwords
If you are opening KeePass databases which use master passwords, you can store these passwords in your PowerPass Locker to keep them secure.
# Additional Information
## About KeePassLib
PowerPass comes bundled with the KeePassLib 2.55 source code which is copyright 2003-2023 Dominik Reichl <dominik.reichl@t-online.de> and is licensed under the GNU Public License 2.0. A copy of this license is included in the LICENSE file in this repository. KeePassLib has not been modified from its release version. You can use PowerPass with KeePassLib 2.55 or with your own version of KeePassLib.
## Test Database Password
You can alter the KeePass test database if you like. The master password to the test database TestDatabase.kdbx is "12345" without the quotation marks. The test database is stored in the module deployment directory.
## Unit Testing
You can run all the unit tests developed for PowerPass by running the `Test-PowerPass.ps1` script in the `PowerPassTests` directory after deploying the module. This script runs a series of unit tests against PowerPass to ensure that all functionality works as designed.