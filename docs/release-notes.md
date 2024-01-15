# Release Notes
The latest release of PowerPass version 1.6.0 adds support for attachments. You can now add, update and remove attachments from your PowerPass locker. Attachments can be added with any filename, including a full path, so they can easily be exported to the current directory, an arbitrary directory, or the original location from where they were imported.
# Attachments
Release 1.6.0 of PowerPass adds six (6) new cmdlets:
1. `Add-PowerPassAttachment` - add attachments in bulk from the file system
2. `Export-PowerPassAttachment` - save attachments from your locker to files on disk
3. `Get-PowerPassAttachments` - list all attachments in your locker
4. `Read-PowerPassAttachment` - get an attachment from your locker
5. `Remove-PowerPassAttachment` - delete an attachment from your locker
6. `Write-PowerPassAttachment` - add a single attachment to your locker

Using these cmdlets you can easily add attachments to your encrypted PowerPass locker, fetch their contents at a later date, or hide files from the file system by adding files to your locker, deleting them from the file system, then exporting them later when they are needed.
# Deployment
The deployment script has been modified and is now much quieter than before. To install PowerPass:
1. Clone the repo, download the release, or download the source code for this release
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder)

For detailed information about deployment see the [Deployment](https://chopinrlz.github.io/powerpass/deployment) article in the online documentation.
# File Hashes
| Release                 | SHA256 Hash                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| PowerPass-1.6.0.tar.gz  | `D1A79F98FFE3B57BD0C7E06D94B8D2ECD0894E6FF2D7DDCE443288CCD4716230` |
| PowerPass-1.6.0.zip     | `83157F25C5329881779202B78DF5463EE0B1736EE691EB41A34669D59EE81A00` |

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)