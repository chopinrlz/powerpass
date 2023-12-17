# [Deployment](#deployent) and [Usage](#usage)
## Deployment
PowerPass comes with a deployment script which will compile the KeePassLib source code, generate a PowerPass module salt (for salting Locker keys), and deploy the module. You can deploy the module to your user profile home directory for yourself, or you can deploy the module for all users (which requires administrative permissions).
### Step 1: Clone the Repository or Download a Release
Clone this repository to a **writeable** folder on your local machine or download and unzip a release.
You must have write permissions to this folder.
### Step 2: Run Deploy-PowerPass.ps1
Open your target PowerShell environment and run `.\Deploy-PowerPass.ps1`.
Follow the prompts to deploy PowerPass.
> If you are using Windows PowerShell you will be prompted to install either the (1) AES or (2) DP API with KeePass support variant.
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
# Unit Testing
Each version of PowerPass is unit tested prior to release.
There are three unit test batteries for PowerPass located in the `test` folder in this repo.
## AES Unit Tests
Unit testing the AES edition of PowerPass can be done by running the `Test-ModuleAes.ps1` script in Windows PowerShell or PowerShell 7.
## Data Protection API Tests
Unit testing the Data Protection API edition of PowerPass can be done by running the `Test-ModuleDpApi.ps1` script in Windows PowerShell.
This test battery will also test the KeePass 2 integration.
## AES Crypto Unit Tests
Unit testing the AES crypto class source code included with PowerPass can be done by running `Test-AesCrypto.ps1` script in Windows PowerShell or PowerShell 7.
This test battery tests the `AesCrypto.cs` implementation found in the `module` folder which implements the 256-bit AES encryption and decryption routines native to .NET and the underlying operating systems on which .NET runs.
This source code uses the `Aes` and `CryptoStream` classes found in the `System.Security` or `System.Security.Cryptography` namespaces in the .NET Framework and .NET, respectively, to encrypt and decrypt data using symmetric key AES encryption.
Keys are generated using the `RandomNumberGenerator` class from the aforementioned namespaces.
# Additional Information
## About KeePassLib
PowerPass comes bundled with the KeePassLib 2.55 source code which is copyright 2003-2023 Dominik Reichl <dominik.reichl@t-online.de> and is licensed under the GNU Public License 2.0. A copy of this license is included in the LICENSE file in this repository. KeePassLib has not been modified from its release version. You can use PowerPass with KeePassLib 2.55 or with your own version of KeePassLib.
## Test Database Password
You can alter the KeePass test database if you like. The master password to the test database TestDatabase.kdbx is "12345" without the quotation marks. The test database is stored in the module deployment directory.
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)