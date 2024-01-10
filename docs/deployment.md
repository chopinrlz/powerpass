# Deployment
#### _Revised: January 9, 2024_
PowerPass is not your typical PowerShell module.
It works like a module, it's deployed like a module, but due to its nature it must be deployed using a deployment script packaged with PowerPass.
Depending on the edition of PowerPass that you want to use, the AES edition or the Data Protection API edition (and in the future the TPM edition), PowerPass has different dependencies and requirements that are validated and/or configured at deployment time.
<br/>

Some of these dependencies are tied to your specific local logon account and cannot be packaged in the way a standard PowerShell module is packaged.
This guide will walk you through the deployment of PowerPass on Linux, MacOS, and Windows using the provided `Deploy-PowerPass.ps1` script.
<br/>

First, you must install [PowerShell](https://github.com/PowerShell/PowerShell) if you haven't done so already, unless you are on Windows and plan to use Windows PowerShell which is built-in. If you already have PowerShell installed, follow the [Quick Start](#quick-start) next or skip ahead to [Deploying PowerPass](#deploying-powerpass).
# Quick Start
### Deploying from Git on macOS and Linux
On Linux or macOS, you can open a terminal and use these commands to clone the repo and deploy PowerPass from your home directory.
```bash
$ cd ~
$ git clone https://github.com/chopinrlz/powerpass.git
$ cd powerpass
$ pwsh
PS> ./Deploy-PowerPass.ps1
```
### Deploying from Git on Windows
On Windows, you can open the Terminal and use these commands to clone the repo and deploy PowerPass from your user profile folder on Windows PowerShell 5.1.
```powershell
C:\Users\janedoe> cd Documents
C:\Users\janedoe\Documents> git clone https://github.com/chopinrlz/powerpass.git
C:\Users\janedoe\Documents> cd powerpass
C:\Users\janedoe\Documents\powerpass> powershell
PS C:\Users\janedoe\Documents\powerpass> .\Deploy-PowerPass.ps1
```
# Installing PowerShell
## Linux
PowerPass runs on PowerShell 7 on Linux.
### _[Main Article: Installing PowerShell on Linux](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.4)_
PowerPass on Linux requires PowerShell 7 which is provided for many distros as an installable package.
If you do not already have PowerShell 7 installed on your Linux distro, you can browse the [PowerShell readme file](https://github.com/PowerShell/PowerShell/blob/master/README.md) on GitHub for instructions on installing PowerShell 7 for your distro.
<br/>
Supported distros currently include:
1. CentOS 7/8
2. Debian 10/11
3. Fedora 35
4. openSUSE 42.3
5. Red Hat Enterprise 7
6. Ubuntu 16.04 through 22.04  

Once PowerShell 7 is installed, simply run the [deployment](#deploying-powerpass) script in PowerShell 7 to deploy PowerPass.
## MacOS
PowerPass runs on PowerShell 7 on macOS.
### _[Main Article: Installing PowerShell on macOS](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.4)_
PowerPass on MacOS requires PowerShell 7 which is supported on macOS 10.13 and higher on x64 processors and macOS 11 and higher on arm64 processors.
<br/>

If you do not already have PowerShell 7 installed on your Mac, you can browse the [PowerShell readme file](https://github.com/PowerShell/PowerShell/blob/master/README.md) on GitHub to find the release for your hardware and macOS version.
<br/>

Once PowerShell 7 is installed, simply run the [deployment](#deploying-powerpass) script in PowerShell 7 to deploy PowerPass.
## Windows
PowerPass runs on Windows PowerShell 5.1 or PowerShell 7 on Windows.
You will also need the .NET Framework 4.8.1 or higher if you use the Data Protection API edition.
### _[Main Article: Installing PowerShell on Windows](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4)_
Installing PowerShell 7 on Windows can be done by downloading and running the installer from the [latest release](https://github.com/PowerShell/PowerShell/releases) of PowerShell on GitHub.

# Deploying PowerPass
PowerPass comes with a deployment script which will verify and/or create all the prerequisites for you. For the Data Protection API edition it will compile the KeePassLib source code, generate a PowerPass module salt (for salting Locker keys), and deploy the module.
For the AES edition it will generate a key for you and deploy the module.
<br/>

PowerPass is ALWAYS deployed to YOUR user's home directory.
PowerPass must be deployed once for each user who needs to use it.
PowerPass does NOT require administrative permissions.
PowerPass should NOT be deployed with administrative permissions.
PowerPass is designed to run under USER permissions within the user's home directory.
<br/>

For details on prerequisites for each implementation, please see the [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) page.

## Step 1: Clone the Repository or Download a Release
Clone https://github.com/chopinrlz/powerpass.git to a **writeable** folder on your local machine OR download and unpack **[the latest release](https://github.com/chopinrlz/powerpass/releases)**.
You must have write permissions to this folder.
You must have `git` installed to clone the repo from GitHub.
You can download Git from [here](https://git-scm.com/downloads), but on Linux your distro likely has a package which includes git.
## Step 2: Run Deploy-PowerPass.ps1
Open your target PowerShell environment, either PowerShell 7 or Windows PowerShell.
Set the directory to the path where you cloned PowerPass or unpacked the release.
Run `.\Deploy-PowerPass.ps1`
Follow the prompts to deploy PowerPass.
> If you are using Windows PowerShell you will be prompted to install either the (1) AES or (2) DP API with KeePass support variant.
</br>

## Step 3: Verify the Deployment
After PowerPass is deployed, open a new PowerShell window and enter the following commands:
```powershell
PS> Import-Module PowerPass
PS> Get-PowerPass
```
Running `Get-PowerPass` will output the PowerPass installation details onto the console.
<br/>

They will look like this:
#### For the Data Protection API Edition
```powershell
KeePassLibraryPath : C:\Users\janedoe\Documents\WindowsPowerShell\Modules\PowerPass\KeePassLib.dll
KeePassLibAssembly : KeePassLib, Version=2.55.0.25753, Culture=neutral, PublicKeyToken=null
TestDatabasePath   : C:\Users\janedoe\Documents\WindowsPowerShell\Modules\PowerPass\TestDatabase.kdbx
StatusLoggerSource : C:\Users\janedoe\Documents\WindowsPowerShell\Modules\PowerPass\StatusLogger.cs
ExtensionsSource   : C:\Users\janedoe\Documents\WindowsPowerShell\Modules\PowerPass\Extensions.cs
ModuleSaltFilePath : C:\Users\janedoe\Documents\WindowsPowerShell\Modules\PowerPass\powerpass.salt
AesCryptoSource    : C:\Users\janedoe\Documents\WindowsPowerShell\Modules\PowerPass\AesCrypto.cs
CommonSourcePath   : C:\Users\janedoe\Documents\WindowsPowerShell\Modules\PowerPass\PowerPass.Common.ps1
LockerFolderPath   : C:\Users\janedoe\AppData\Local\PowerPassV1
LockerFilePath     : C:\Users\janedoe\AppData\Local\PowerPassV1\powerpass.locker
LockerSaltPath     : C:\Users\janedoe\AppData\Local\PowerPassV1\locker.salt
Implementation     : DPAPI
```
#### For the AES Edition
```powershell
AesCryptoSourcePath : C:\Users\janedoe\Documents\PowerShell\Modules\PowerPass\AesCrypto.cs
CommonSourcePath    : C:\Users\janedoe\Documents\PowerShell\Modules\PowerPass\PowerPass.Common.ps1
LockerFolderPath    : C:\Users\janedoe\Documents
LockerFilePath      : C:\Users\janedoe\Documents\.powerpass_locker
LockerKeyFolderPath : C:\Users\janedoe\AppData\Local\powerpassv2
LockerKeyFilePath   : C:\Users\janedoe\AppData\Local\powerpassv2\.locker_key
Implementation      : AES
```
PowerPass is now ready for use.
## Step 4: (Optional) Test the Deployment
You can test the deployment with one of these cmdlets:
1. Open-PowerPassTestDatabase (DP API only)
2. Read-PowerPassSecret (DP API or AES)
<br/>

Running `Open-PowerPassTestDatabase` (DP API only) will load the KeePass test database bundled with the repository confirming that KeePassLib compiled successfully and can read KeePass databases.
Running `Read-PowerPassSecret` will initialize your PowerPass Locker with a default secret and output it to the pipeline.
This will confirm the Locker functionality of PowerPass is working properly.
# Additional Information
## About KeePassLib
PowerPass comes bundled with the KeePassLib 2.55 source code which is copyright 2003-2023 Dominik Reichl <dominik.reichl@t-online.de> and is licensed under the GNU Public License 2.0. A copy of this license is included in the LICENSE file in this repository. KeePassLib has not been modified from its release version. You can use PowerPass with KeePassLib 2.55 or with your own version of KeePassLib.
## Test Database Password
You can alter the KeePass test database if you like. The master password to the test database TestDatabase.kdbx is "12345" without the quotation marks. The test database is stored in the module deployment directory.
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)