This latest major release of PowerPass introduces in-memory security hardening, custom file path settings, and adds merge support to the Data Protection API edition. This is a breaking change from previous versions of PowerPass. **If you are running PowerPass v2.x your locker will be updated automatically. However, if you are still using PowerPass v1.x you will need to export your locker prior to deploying PowerPass v3.**
#### Breaking Changes
Locker secrets are now double-key encrypted. **PowerPass v1.x and PowerPass v2.x Lockers are not compatible with PowerPass v3.x. and vice versa.** Users on PowerPass v2.x can upgrade automatically using the `Deploy-PowerPass.ps1` script. PowerPass v1.x users will need to export their Lockers and re-import them manually.
#### Automated Upgrade Path
Version 3 of PowerPass introduces a new property to the Locker which tracks the revision. A new upgrade cmdlet named `Update-PowerPass` will update your v2.x Lockers to v3.x format, since the new format uses double-key encryption. **The deployment script will automatically invoke this cmdlet for you during install.** This has prevented the addition of extra code into the module for run-time checking and updating avoiding performance penalties from supporting legacy Locker revisions.

Here is the full changelog:
# New Features
## In-Memory Security Hardening
A major update to the PowerPass run-time has been introduced to protect against in-memory attack vectors. When your Locker is loaded from disk, the decrypted contents of the Locker's secrets remain protected with a one-time pad while resident in memory until you fetch them with `Read-PowerPassSecret`. This feature was added to protect from rogue processes which might access your PowerShell process memory to avoid scraping all your Locker secrets from memory in plain-text. The Locker secrets text properties are now double-key encrypted when stored on disk: first with an ephemeral one-time pad and secondly with a 256-bit AES key. Older versions of PowerPass will not be able to read these Lockers. Exported Lockers will not include this double-key encryption so they can continue to be portable.
## Custom File Path Settings
The AES edition of PowerPass has been enhanced to provide support for custom file paths for your Lockers and Locker keys. You are no longer required to store your Lockers or Locker keys in the default directories based on your user profile's user data and app data directories. The new `Set-PowerPass` cmdlet will allow you to change these paths and will store these settings in a custom settings file. You can also reset the settings back to their defaults allowing you to load a secondary/tertiary/etc. Locker at run-time then drop back to your default Locker. This functionality allows for more durable deployments where Lockers and Locker keys can be stored on different computers, a good practice for secure computing.
## Merge Import
### Attachments
The `Merge` import option for an exported Locker will now merge attachments into the local Locker as well as secrets.
### Merge by Date
The `Merge` import option has been enhanced with the `ByDate` switch allowing the user to import an external Locker file and merge it into the local Locker but for only secrets and attachments that are newer. This enhancement is particularly useful if you use PowerPass to synchronize credentials across a network of computers and you do not want to erase local secret updates that may take precedence.
### Data Protection API Edition
The `Merge` option has been added to the Data Protection API edition's `Import-PowerPassLocker` cmdlet.
# Security Updates, Optimizations, and Bug Fixes
## Buffer Security
A new routine has been added to the `PowerPass.AesCrypto` provider called `EraseBuffer` for erasing in-memory data buffers with random data rather than zeroes, as was being done before. When you erase the data inside of a fixed-length array with zeros it creates a findable location in your application memory. If a rogue process attaches to your process, it can find these memory locations by looking for blocks of zeroes. This presents a security concern. By filling these arrays with random data instead it makes it more difficult for an attacking process to locate memory locations with sensitive information. This routine has been incorporated into areas of PowerPass which load sensitive information into `[byte[]]` memory buffers.
## Attachment Size Warning Suppression
The `Read-PowerPassAttachment` cmdlet would previously output a warning if it encountered an attachment of 10 MiB or greater. This has been suppressed to avoid pushing non-attachment content to the output stream, potentially breaking the cmdlet.
## Common Code Optimizations
A full code review was performed between the AES edition and the DP API edition to identify all common code shared between the editions. All common code was promoted to the `PowerPass.Common.ps1` script file making the module files themselves slightly more compact and more efficient.
## Documentation Refresh
All of the online documentation has been refreshed to include examples for all the new functionality as well as correcting and refining coverage of existing functionality. Formatting has been updated and inaccurate or deprecated examples have been removed. Some missing documentation has been added.
# Deployment
To install PowerPass:
1. Download this release below, download the source code for this release, or clone to repo (for a dev build).
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder if you plan to compile KeePass or use the DP API edition)
3. You will see a notice about your Locker being updated to the latest edition, or that it's already v3.x

For detailed information about deployment see the [Deployment](https://chopinrlz.github.io/powerpass/deployment) article in the online documentation.
# File Hashes
| Release                 | SHA256 Hash                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| PowerPass-3.0.1.tar.gz  | `29D8B41DBA34D2515D32E27B1EC77F732E44B7F51295510AF8DFC1C546554E41` |
| PowerPass-3.0.1.zip     | `AB33AE298B494AEB2DC699DA53BA23F93EB1D4BD4E31576FBF73914473AE4CF3` |

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [How It Works](https://chopinrlz.github.io/powerpass/readme-cont) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Roadmap](https://chopinrlz.github.io/powerpass/roadmap) | [Usage](https://chopinrlz.github.io/powerpass/usage)