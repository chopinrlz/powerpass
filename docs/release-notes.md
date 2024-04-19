**NOTE: This is a BREAKING CHANGE from v1.x. If you are on v1.x please EXPORT your Locker before deploying v2.x.** If your forget to do this, simply go back to v1.6.2, export your Locker, then deploy v2.1.0. PowerPass will not overwrite your Locker or your Locker keys if they already exist.
# Bug Fixes
## [Excessive memory usage and long processing delay when fetching large attachments](https://github.com/chopinrlz/powerpass/issues/5)
Release v2.1.2 resolves issue #5. This issue was causing large processing delays and memory leaks with large attachments. See details below in Performance Optimization.
# Performance Optimization
## AMSI Workaround
This release of PowerPass includes a performance optimization for large attachments. In PowerShell 7 and above, there is an anti-malware subsystem which will engage on certain calls to .NET CLR functions causing a severe performance penalty with larger attachments. While it is not advised to store large attachments with PowerPass (files over 10 MiB in size), you can certainly do so if needed. The optimizations in PowerPass v2.1.1 and v2.1.2 eliminates the overhead of the calls to the anti-malware subsystem when attachments are read from and written into your Locker. Your anti-virus software will still monitor file system access (assuming you have it enabled on your computer), but it will no longer monitor in-memory attachment read operations performed by PowerPass itself.
## Write-Output Memory Leak
This release of PowerPass also fixes an issue which occurs when you retrieve large attachments from your Locker. In Windows PowerShell 5.1 the `Write-Output` cmdlet leaks memory and never completes with large `[byte[]]` attachments, such as those that are in the 200 MiB or larger range.
# Deployment
To install PowerPass:
1. Clone the repo, download this release, or download the source code for this release
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder)

For detailed information about deployment see the [Deployment](https://chopinrlz.github.io/powerpass/deployment) article in the online documentation.
# File Hashes
| Release                 | SHA256 Hash                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| PowerPass-2.1.2.tar.gz  | `E262090BFA88A3F5EC4F3BFB312283C7930E415ED39C78074BF09DE5EBB59ACD` |
| PowerPass-2.1.2.zip     | `E71C7B0D6B4A75A5CEB3D30FB43762CE2DFBA95C4357CFA48FE80A00EE50276E` |

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)