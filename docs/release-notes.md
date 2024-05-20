**NOTE: This is a BREAKING CHANGE from v1.x. If you are on v1.x please EXPORT your Locker before deploying v2.x.** If your forget to do this, simply go back to v1.6.2, export your Locker, then deploy v2.2.1. PowerPass will not overwrite your Locker or your Locker keys if they already exist.
# Bug Fixes
### [[macOS] Lockers cannot be opened after reboot](https://github.com/chopinrlz/powerpass/issues/7)
Release 2.2.1 fixes a bug in macOS where ephemeral key generation uses the MAC address of an adapter with a dynamic address assigned at start up. After rebooting your Mac, you could no longer read secrets from your Locker. The fix excludes two adapaters from consideration as candidates for ephemeral key generation to avoid this problem.
# Deployment
To install PowerPass:
1. Clone the repo, download this release, or download the source code for this release
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder)

For detailed information about deployment see the [Deployment](https://chopinrlz.github.io/powerpass/deployment) article in the online documentation.
# File Hashes
| Release                 | SHA256 Hash                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| PowerPass-2.2.1.tar.gz  | `C5CD4628C3B520F4B8A2F36BE3FDDF5BF031386A03B029A98B63A0CF8AE6D4CD` |
| PowerPass-2.2.1.zip     | `D180B0CD907B549F861D6324CB0D78F00AAF6691CB21137F0A0A028456309D15` |

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [How It Works](https://chopinrlz.github.io/powerpass/readme-cont) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)