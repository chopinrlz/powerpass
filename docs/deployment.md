# [Deployment](#deployent) and [Usage](#usage)
## Deployment
PowerPass comes with a deployment script which will compile the KeePassLib source code, generate a PowerPass module salt (for salting Locker keys), and deploy the module. You can deploy the module to your user profile home directory for yourself, or you can deploy the module for all users (which requires administrative permissions).
### Step 1: Clone the Repository or Download a Release
Clone this repository to a **writeable** folder on your local machine or download and unzip a release.
You must have write permissions to this folder.
### Step 2: Run Deploy-PowerPass.ps1
Open your target PowerShell environment and run `.\Deploy-PowerPass.ps1`.
Follow the prompts to deploy PowerPass.
```
If you are using Windows PowerShell you will be prompted to install either the (1) AES or (2) DP API with KeePass support variant.
```
### Step 3: Verify the Deployment
You can test the deployment with these cmdlets:
1. Open-PowerPassTestDatabase (DP API only)
2. Read-PowerPassSecret

Running `Open-PowerPassTestDatabase` (DP API only) will load the KeePass test database bundled with the repository confirming that KeePassLib compiled successfully and can read KeePass databases.
Running `Read-PowerPassSecret` will initialize your PowerPass Locker with a default secret and output it to the pipeline.
This will confirm the Locker functionality of PowerPass is working properly.
For details on prerequisites for each implementation, please see the [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) page.
## Usage
## KeePass Databases
To open a KeePass database use the `Open-PowerPassDatabase` cmdlet.
Pipe or pass the output to `Get-PowerPassSecret` to fetch secrets from the KeePass database.
## PowerPass Locker
To read a secret from your PowerPass Locker use the `Read-PowerPassSecret` cmdlet.
To write a secret into your PowerPass Locker use the `Write-PowerPassSecret` cmdlet.
## Storing KeePass Database Passwords
If you are opening KeePass databases which use master passwords, you can store these passwords in your PowerPass Locker to keep them secure.
# Cmdlet Reference
1. For the AES edition: [PowerPass AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref)
2. For the DP API edition: [PowerPass DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref)

Additional information below.
# Additional Information
## About KeePassLib
PowerPass comes bundled with the KeePassLib 2.55 source code which is copyright 2003-2023 Dominik Reichl <dominik.reichl@t-online.de> and is licensed under the GNU Public License 2.0. A copy of this license is included in the LICENSE file in this repository. KeePassLib has not been modified from its release version. You can use PowerPass with KeePassLib 2.55 or with your own version of KeePassLib.
## Test Database Password
You can alter the KeePass test database if you like. The master password to the test database TestDatabase.kdbx is "12345" without the quotation marks. The test database is stored in the module deployment directory.
## Unit Testing
You can run all the unit tests developed for PowerPass by running the `Test-PowerPass.ps1` script in the `PowerPassTests` directory after deploying the module. This script runs a series of unit tests against PowerPass to ensure that all functionality works as designed.
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)