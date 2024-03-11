**NOTE: This is a BREAKING CHANGE from v1.x. If you are on v1.x please EXPORT your Locker before deploying v2.x.**
If your forget to do this, simply go back to v1.6.2, export your Locker, then deploy v2.0.0.
PowerPass will not overwrite your Locker or your Locker keys if they already exist.
# Release Notes
The latest release of PowerPass version 2.0.0 breaks away from an old methodology for generating ephemeral keys within the AES edition of PowerPass.
v2.x will not be able to open v1.x Lockers on the AES edition.
The key format is not the same.
## Key Generation
In the v1.x branch of PowerPass, AES-encrypted Locker keys were protected with an ephemeral key based on the current environment.
This key was generated using command-line utilities, and while it was functional, it was liable to fail and throw an error, halting execution of the module.
In the v2.x branch of PowerPass, ephemeral keys are generated using the cross-platform .NET `System.Net.NetworkInformation` namespace and the `System.Environment` class.
While this makes the implementation more durable and tolerant to more scenarios, it effectively causes a change in the key format and thus breaks from the v1.x branch of PowerPass.
# Data Protection Edition
The DP API edition of PowerPass in v2.0.0 is identical to v1.6.2.
Nothing has changed other than the fact that the `Get-PowerPassEphemeralKey` cmdlet is now part of `PowerPass.Common.ps1` since it is now compatible with Linux, MacOS, and Windows using a single implementation available in both .NET and the .NET Framework.
# Deployment
To install PowerPass:
1. Clone the repo, download this release, or download the source code for this release
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder)

For detailed information about deployment see the [Deployment](https://chopinrlz.github.io/powerpass/deployment) article in the online documentation.
# File Hashes
| Release                 | SHA256 Hash                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| PowerPass-2.0.0.tar.gz  | `6CE4F0EC8B360AABC2152BF6491A193D7015DD57A7EE0B3DEC40D2A527B66BD0` |
| PowerPass-2.0.0.zip     | `D2F9BF9EF903F54BAE18F8E8F5DA61E9DA2C7D3A3B186BFA0A3374532BC2C3D7` |

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)