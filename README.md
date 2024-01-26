# PowerPass
A cross-platform PowerShell module for secret storage and retrieval on Linux, MacOS, and Windows.
PowerPass supports Windows PowerShell 5 and PowerShell 7.
## Purpose
PowerPass provides an easy to use set of cmdlets for securely storing and retrieving credentials automatically without user input.
In automated scenarios, there is no user present to type in a set of credentials.
PowerPass facilitates the use of credentials in automated scenarios.
PowerPass credentials are locked down so that only the user who stored them can access them.
PowerPass retrieves credentials automatically for the current user.
For more information on how to use PowerPass, please review [Incorporating PowerPass into your Scripts](https://chopinrlz.github.io/powerpass/usage).
## Encryption Standards
PowerPass comes in two flavors, with a third pending:
1. 256-bit AES Encryption
2. Windows Data Protection API
3. TPM Encryption (in development, scroll to bottom)
## Compatibility
1. The AES edition supports PowerShell on Linux, MacOS, and Windows and will run in either Windows PowerShell or PowerShell 7.
2. The Data Protection API edition supports Windows PowerShell as well as KeePass 2 databases, but can only be used on Windows in Windows PowerShell.
3. If you deploy PowerPass from PowerShell 7 it will automatically deploy the AES edition.
4. You can see what flavor of PowerPass you are using by running `(Get-PowerPass).Implementation` which will echo either `AES` or `DPAPI` depending on which module flavor was deployed.
## Documentation
For information about PowerPass and cmdlet reference please browse the [online documentation](https://chopinrlz.github.io/powerpass).
# Deployment and Usage
PowerPass comes with a deployment script called `Deploy-PowerPass.ps1` which will install the module for you.
You must use this script to install PowerPass.
Run this script in any PowerShell terminal you like to install PowerPass.
For detailed deployment and usage instructions please see [Deployment and Usage](https://chopinrlz.github.io/powerpass/deployment) in the online documentation.
# How It Works
## AES
PowerPass on Linux, MacOS, or Windows in PowerShell 7 can read and write secrets from PowerPass Lockers encrypted with AES.
### PowerPass Lockers
A Locker is a 256-bit AES encrypted file which stores your secrets and their metadata in UTF-8 JSON format.
The AES implementation used is native to the operating system on which it runs.
Linux, MacOS, and Windows all provide native 256-bit AES block cipher encryption.
#### Locker Keys
AES locker keys are generated automatically using the cryptographic random number generator class.
All locker keys are 256-bits in length.
This is the maximum AES key length supported by .NET on all operating systems.
#### Key Generation and Storage
When you first use PowerPass, the module will generate a key for you.
The key is generated using the cryptographic random number generator.
The Locker is stored in your home directory while the key is stored in your application data directory.
These directories can only be accessed by you, but can also be accessed by anyone with admin rights to the computer, so bear that in mind when you store secrets in your Locker.
The Locker is encrypted with the key while the key is encrypted with an ephemeral key that is based on your hostname, username, and primary MAC address.
You can get the file paths to you locker and key files using the `Get-PowerPass` cmdlet.
#### Precautions
If you are using the AES edition of PowerPass, please be aware of the following precautions:
1. Your Locker key is linked to your login name, hostname, and primary MAC address
2. This linkage is **case-sensitive**
3. Changing your login name, hostname, or primary MAC address will make your Locker inaccessible
4. If you need to change any of the above, take a backup of your Locker then restore it after you make the changes

Tl; dr: don't change your username, hostname, or primary MAC address without backing up your Locker first.
#### Exporting and Importing your Locker
You can export your locker to save a backup copy elsewhere.
When you export your locker, you specify a password to encrypt the locker.
The password must be between 4 and 32 characters in length.
#### Rotating your Locker Key
You can also rotate your locker key automatically.
When you rotate your locker key PowerPass will decrypt your locker, generate a new key, encrypt your locker with the new key, and encrypt the new key with the ephemeral key.
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
#### Salting
To increase the difficulty of attackers brute-force decrypting your Locker, the Locker is salted with a random key which is in turn salted by the PowerPass random key generated at deployment time.
These random keys are generated using the cyrptographic random number generator.
#### Locker and Key Storage
The Locker is stored in your Application Data folder along with the salt file.
Meanwhile, there is a secondary salt file stored in the module's folder.
All three files are encrypted with the Data Protection API.
Your locker and locker salt are encrypted at the user scope while the module salt is encrypted at the machine scope.
You can get the file paths using the `Get-PowerPass` cmdlet.
#### Precautions
If you are using the DP API edition of PowerPass, please be aware of the following precautions:
1. Your Locker key is linked to your Windows user account
2. This linkage is built-in to the Windows profile manager
3. If you remove your user profile, your Locker will be deleted

Your Locker is linked to your local Windows user profile.
Always backup your Locker if you plan to make any changes to your local Windows user profile, such as if you are deleting it to have Windows recreate it due to profile directory issues.
#### Exporting your Locker and Key
You can export your locker and key to save a backup copy elsewhere.
You can also rotate your locker salts automatically, but the locker key is built-in to your Windows profile.
The Data Protection API does not allow you to explicitly rotate your user profile key.
# Additional Resources
## License and Copyright
PowerPass is copyright 2023-2024 by The Daltas Group LLC.
PowerPass is open-source, free software. You may use PowerPass for any purpose.
PowerPass is licensed under the GNU Public License v2.0.
The license can be found in the [LICENSE](https://github.com/chopinrlz/powerpass/blob/main/LICENSE) file.
You may copy, modify, and distribute PowerPass for personal or commercial use under the terms of the GNU Public License v2.0.
## Online Documentation
For cmdlet reference and usage information, please refer to the online documentation links below.
1. [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref)
2. [Data Structures](https://chopinrlz.github.io/powerpass/data-structures)
3. [Deployment](https://chopinrlz.github.io/powerpass/deployment)
4. [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials)
5. [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref)
6. [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup)
7. [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites)
8. [Release Notes](https://chopinrlz.github.io/powerpass/release-notes)
9. [Usage](https://chopinrlz.github.io/powerpass/usage)
## Repository Directory
The directory of assets in this repo can be found in the [REPO](https://github.com/chopinrlz/powerpass/blob/main/REPO.md) markdown file.
# Roadmap
Here is the roadmap of upcoming features.
## TPM Support on Linux
Currently under development is TPM support for Linux.
| As of January 26, 2024 | Status |
| --- | --- |
| Initalize Context | Complete |
| Get Info | Complete |
| Create Key | Pending |
| Encrypt Locker | Pending |
| Decrypt Locker | Pending |
| Unit Testing | Available |

The library chosen to provide support is the open-source **[tpm2-tss](https://github.com/tpm2-software/tpm2-tss)** project.
A TPM is a Trusted Platform Module which is a device that stores private keys which cannot be exported from the system by any user.
The TPM device can be used to encrypt data without exposing the private keys to either admins or users.
As such, an attacker with root privileges would have no means of acquiring the key to decrypt the data leaving brute-force as the only option.
Check the [/tpm](https://github.com/chopinrlz/powerpass/tree/main/tpm) folder in this repo for ongoing updates.
### Can I use PowerPass TPM Edition?
If you are using Linux, the answer is (almost certainly) Yes.
You will first need to compile the **[tpm2-tss](https://github.com/tpm2-software/tpm2-tss)** source and deploy the binaries for your Linux distro.
The **tpm2-tss** project has an install guide [here](https://github.com/tpm2-software/tpm2-tss/blob/master/INSTALL.md).
This project supports all major Linux distros including Debian, Fedora, and Ubuntu.

Once you have **tpm2-tss** deployed you can test for TPM support by running `Test-TpmProvider.ps1` from the `/tpm` directory in this repo.
This PowerShell script will compile the `powerpasstpm` binary using `gcc` via the included `makefile` then run it in test mode and fetch the TPM info from the **tpm2-tss** Feature API.
### Compiling
The PowerPass TPM edition module is called `powerpasstpm`.
The module is written in `C` and is compiled using the GNU Compiler Collection or `gcc`.

1. To compile `powerpasstpm` simply run `make`
2. To clean up and recompile `powerpasstpm` run `make clean` then `make` again

The `makefile` in the `/tpm` directory assumes your **tpm2-tss** libraries are in `/usr/local/lib`.
If they are elsewhere, you will have to edit the `makefile` for now at least until I make it dynamic.
### Testing
You can test `powerpasstpm` with the included `Test-TpmProvider.ps1` PowerShell script or you can just run `powerpasstpm` from the shell.
| Test commands |||
| -- | -- | -- |
| ./powerpasstpm test | Runs in test mode | Outputs TPM info in JSON format to the console |
| ./powerpasstpm test > info.json | Runs in test mode | Saves TPM info to JSON file for review |

The `test` action for `powerpasstpm` invokes the `Fapi_GetInfo` function of the [TCG TPM2 Feature API](https://trustedcomputinggroup.org/resource/tss-fapi/) which echoes all the TPM capabilities of your system in JSON format.