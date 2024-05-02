**NOTE: This is a BREAKING CHANGE from v1.x. If you are on v1.x please EXPORT your Locker before deploying v2.x.** If your forget to do this, simply go back to v1.6.2, export your Locker, then deploy v2.2.0. PowerPass will not overwrite your Locker or your Locker keys if they already exist.
# New Features
### Importing Secrets from KeePass 2 Databases
Version 2.2.0 of PowerPass adds a new feature to the Data Protection API edition for Windows PowerShell. The newly added `Import-PowerPassSecrets` cmdlet allows you to copy all the secrets from a KeePass 2 database into your PowerPass Locker so that they can be exported to a separate location, like another computer, or used from your Locker instead.
### Version Number
Version 2.2.0 of PowerPass adds the module version to the output of `Get-PowerPass` using the `Version` property which will allow you to easily fetch the version of PowerPass you have deployed.
# Bug Fixes
### [Open-PowerPassDatabase does not honor relative paths](https://github.com/chopinrlz/powerpass/issues/6)
Release 2.2.0 fixes a bug in the Data Protection API edition of PowerPass when working with KeePass 2 databases. The `Open-PowerPassDatabase` cmdlet had an error with the `-Path` parameter where relative paths were ignored and caused the cmdlet to report an error that it cannot find the database file.
# Deployment
To install PowerPass:
1. Clone the repo, download this release, or download the source code for this release
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder)

For detailed information about deployment see the [Deployment](https://chopinrlz.github.io/powerpass/deployment) article in the online documentation.
# File Hashes
| Release                 | SHA256 Hash                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| PowerPass-2.2.0.tar.gz  | `DCFC865146CA1AC568AF4065AE7E8E19FF8FFA286628721B6C92E238CA71391C` |
| PowerPass-2.2.0.zip     | `D6AC8F716ED0718F11829CCC64EAB53499644D58DD05B95C49D7EE1D7524A6C4` |

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)