This minor release of PowerPass updates the KeePassLib version to 2.61.1.
* If you are upgrading from 2.x, please review the release notes for [PowerPass v3.0.1](https://github.com/chopinrlz/powerpass/releases/tag/v3.0.1) as there are breaking changes. Using the `Deploy-PowerPass.ps1` script will automatically upgrade your Locker to account for these changes.
* If you are upgrading from 1.x, **you will need to export your Locker before upgrading.** The 1.x Locker format is not backwards compatible with v2.x or v3.x. You will need to export then re-import your Locker to retain your secrets.
# Changelog
## KeePassLib 2.61.1
The KeePassLib version has been updated to the latest v2.61.1.
# Deployment
To install PowerPass:
1. Download this release below, download the source code for this release, or clone to repo (for a dev build).
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder if you plan to compile KeePass or use the DP API edition)
3. You will see a notice about your Locker being updated to the latest edition, or that it's already v3.x

For detailed information about deployment see the [Deployment](https://chopinrlz.github.io/powerpass/deployment) article in the online documentation.
# File Hashes
| Release                 | SHA256 Hash                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| PowerPass-3.0.7.tar.gz  | `B304964F32EAEA054721C12844FD056DBC9FE3F8355CEDCFD691D066BBA3EE28` |
| PowerPass-3.0.7.zip     | `43D8D143C2CC4619B6A69E9C9E3D00363AA5E9379BD2EDE17C3AA08B65A42D72` |


# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [How It Works](https://chopinrlz.github.io/powerpass/readme-cont) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Roadmap](https://chopinrlz.github.io/powerpass/roadmap) | [Usage](https://chopinrlz.github.io/powerpass/usage)