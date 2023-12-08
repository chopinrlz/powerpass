The latest release of PowerPass version 1.4.0 incorporates hardening to the AES implementation. It has been tested on Linux and Windows on PowerShell 7 and Windows PowerShell.
# Changelog
### AES Encryption Hardening
The AES implementation has been hardened.
A new function has been added to the module which generates an ephemeral key using details about the local machine, your user account, and the primary network adapter.
This module creates hash of this key using SHA-256 which is used to encrypt the locker's AES key.
If either the Locker file or the Key file are leaked outside the user's home directory or application directory, an attacker will need to brute-force decrypt the Key file to decrypt the Locker file. 
### AES Export and Import Encryption
AES mode Locker exports are now encrypted using a passphrase and key export has been removed.
When you export your Locker, you are prompted for a passphrase which is used to encrypt the Locker.
The same passphrase must be used to import the Locker at a later date.
Your Locker key is not used, nor is it exported.
You can import the Locker from any KeePass 1.4.0 install to any other KeePass 1.4.0 install.
# Deployment
To install:
1. Clone the repo, download the release, or download the source code for this release
2. Run `Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder)
# File Hashes
| Release                 | SHA256 Hash                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| PowerPass-1.3.0.tar.gz  | da9a41fdb16c560b2e8dd847ecbd6d177646891927a998abbfb293f5de7f8664 |
| PowerPass-1.3.0.zip     | 9caa0b08ec08c3305fc307e39791367086d95c34d7d3178a3cc4ba3880b3c518 |