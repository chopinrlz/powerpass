# How It Works
#### _Revised: October 28, 2025_
## AES Edition
PowerPass on Linux, MacOS, or Windows in PowerShell 7 can read and write secrets from PowerPass Lockers encrypted with AES.

### PowerPass Lockers
A Locker is a 256-bit AES encrypted file which stores your secrets and their metadata in UTF-8 JSON format. The AES implementation used is native to the operating system on which it runs. Linux, MacOS, and Windows all provide native 256-bit AES block cipher encryption.

#### Locker Keys
AES locker keys are generated automatically using the cryptographic random number generator class. All locker keys are 256-bits in length. This is the maximum AES key length supported by .NET on all operating systems.

#### Key Generation and Storage
When you first use PowerPass, the module will generate a key for you. The key is generated using the cryptographic random number generator. The Locker is stored in your home directory while the key is stored in your application data directory. These directories can only be accessed by you, but can also be accessed by anyone with admin rights to the computer, so bear that in mind when you store secrets in your Locker. The Locker is encrypted with the key while the key is encrypted with an ephemeral key that is based on your hostname, username, and primary MAC address. You can get the file paths to you locker and key files using the `Get-PowerPass` cmdlet.

#### Precautions
If you are using the AES edition of PowerPass, please be aware of the following precautions:
1. Your Locker key is linked to your login name, hostname, and primary MAC address
2. This linkage is **case-sensitive**
3. Changing your login name, hostname, or primary MAC address will make your Locker inaccessible
4. If you need to change any of the above, take a backup of your Locker with `Export-PowerPassLocker` first then restore it after you make the changes  
<br/>

<blockquote>Tl;dr: DO NOT change your username, hostname, or primary MAC address without backing up your Locker first.</blockquote>

#### Exporting and Importing your Locker
You can export your locker to save a backup copy elsewhere with the `Export-PowerPassLocker` cmdlet. When you export your locker, you specify a password to encrypt the locker. The password must be between 4 and 32 characters in length.

#### Rotating your Locker Key
You can also rotate your locker key automatically. When you rotate your locker key PowerPass will decrypt your locker, generate a new key, encrypt your locker with the new key, and encrypt the new key with the ephemeral key.

## Data Protection API
PowerPass on Windows PowerShell supports secrets from these two sources:

1. KeePass 2 databases
2. PowerPass lockers

### KeePass 2 Databases
KeePass, a .NET Framework application built by Dominik Reichl <dominik.reichl@t-online.de>, is a popular application used for storing and retrieving secrets (like login credentials) from encrypted databases that the KeePass application itself creates. PowerPass builds on top of the core KeePass library to provide programmatic access to KeePass database secrets through the use of Windows PowerShell.

### PowerPass Lockers
A PowerPass Locker is an encrypted file created by PowerPass to store and retrieve secrets which can only be accessed by your user account. After you deploy PowerPass, you can immediately read and write secrets from your Locker. PowerPass Lockers rely on the encryption implementation found in the Windows Data Protection API.

#### Salting
To increase the difficulty of attackers brute-force decrypting your Locker, the Locker is salted with a random key which is in turn salted by the PowerPass random key generated at deployment time. These random keys are generated using the cyrptographic random number generator.

#### Locker and Key Storage
The Locker is stored in your Application Data folder along with the salt file. Meanwhile, there is a secondary salt file stored in the module's folder. All three files are encrypted with the Data Protection API. Your locker and locker salt are encrypted at the user scope while the module salt is encrypted at the machine scope. You can get the file paths using the `Get-PowerPass` cmdlet.

#### Precautions
If you are using the DP API edition of PowerPass, please be aware of the following precautions:

1. Your Locker key is linked to your Windows user account
2. This linkage is built-in to the Windows profile manager
3. If you remove your user profile, your Locker will be deleted

Your Locker is linked to your local Windows user profile. Always backup your Locker if you plan to make any changes to your local Windows user profile, such as if you are deleting it to have Windows recreate it due to profile directory issues.

#### Exporting your Locker and Key
You can export your locker and key to save a backup copy elsewhere using the `Export-PowerPassLocker` cmdlet. You can also rotate your locker salts automatically, but the locker key is built-in to your Windows profile. The Data Protection API does not allow you to explicitly rotate your user profile key.

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [How It Works](https://chopinrlz.github.io/powerpass/readme-cont) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Roadmap](https://chopinrlz.github.io/powerpass/roadmap) | [Usage](https://chopinrlz.github.io/powerpass/usage)