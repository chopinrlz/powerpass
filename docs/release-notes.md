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
| PowerPass-1.4.0.tar.gz  | 18aa2dbbd1adc12b864e63150ee435006cff1e942f3b8eb513928d490b054fcc |
| PowerPass-1.4.0.zip     | 7c601540f66e85628b11aa40e81f160fa4a64716fa65c0be0a5a033e600b3430 |