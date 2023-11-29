The latest release of PowerPass version 1.3.0 is now cross-platform. It has been tested on Linux and Windows on PowerShell 7 and Windows PowerShell.
# New Features
### AES Encryption
This release adds support for 256-bit AES encryption for PowerPass Lockers on all operating systems. The Data Protection API implementation with KeePass 2 support is also included. The deployment script has been updated to allow you to pick which edition you want and will auto-detect PowerShell 7 or Windows PowerShell 5 and provide you with the appropriate deployment options.
### Remove Locker Secrets
This release adds a new cmdlet `Remove-PowerPassSecret` to allow you to remove secrets from your PowerPass Lockers.
# Deprecated Features
### System-wide Deployment
Support for system-wide deployment has been removed from PowerPass as this goes against the principles of data security offered using user-specific encryption keys. You can still install PowerPass into your system folder, but the deployment script only supports user-level deployment which is the recommend use for PowerPass.
# Deployment
To install:
1. Clone the repo, download a release, or download the source code for this release
2. Run `Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder)
# Bug Fixes
### [OneDrive backup changes default PSModulePath](https://github.com/chopinrlz/powerpass/issues/2)
This release fixes this bug. The deployment script will now auto-detect if you have OneDrive Backup enabled and will locate your modules path updated by OneDrive. PowerPass will be deployed to your correct modules folder automatically.
# File Hashes
| Release                 | SHA256 Hash                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| PowerPass-1.3.0.tar.gz  | da9a41fdb16c560b2e8dd847ecbd6d177646891927a998abbfb293f5de7f8664 |
| PowerPass-1.3.0.zip     | 9caa0b08ec08c3305fc307e39791367086d95c34d7d3178a3cc4ba3880b3c518 |