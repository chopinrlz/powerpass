**NOTE: This is a BREAKING CHANGE from v1.x. If you are on v1.x please EXPORT your Locker before deploying v2.x.**
If your forget to do this, simply go back to v1.6.2, export your Locker, then deploy v2.1.0.
PowerPass will not overwrite your Locker or your Locker keys if they already exist.
# Attachment Compression
This latest release of PowerPass v2.1.0 adds support for attachment compression. When loading large attachments into your Locker, add the `-GZip` parameter to compress the file before loading it to your Locker. This works best with large text files, such as CSV or JSON files which contain data, but is not recommended for files which are already compressed.
# Breaking Changes
The v2.x branch of PowerPass breaks away from an old methodology for generating ephemeral keys within the AES edition of PowerPass. v2.x will not be able to open v1.x Lockers on the AES edition. The key format is not the same.
## Key Generation
In the v1.x branch of PowerPass, AES-encrypted Locker keys were protected with an ephemeral key based on the current environment. This key was generated using command-line utilities, and while it was functional, it was liable to fail and throw an error, halting execution of the module. In the v2.x branch of PowerPass, ephemeral keys are generated using the cross-platform .NET `System.Net.NetworkInformation` namespace and the `System.Environment` class. While this makes the implementation more durable and tolerant to more scenarios, it effectively causes a change in the key format and thus breaks from the v1.x branch of PowerPass.
# Deployment
To install PowerPass:
1. Clone the repo, download this release, or download the source code for this release
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder)

For detailed information about deployment see the [Deployment](https://chopinrlz.github.io/powerpass/deployment) article in the online documentation.
# File Hashes
| Release                 | SHA256 Hash                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| PowerPass-2.1.0.tar.gz  | `47743DFC4475F88A5828F8143C59E4D588C48731BE351C40DABE3365B61A0443` |
| PowerPass-2.1.0.zip     | `083A66ADF4D1B4ACF90F08E9FE6C2931F62CA383DB25F697AA8E5A11AFE0D249` |

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)