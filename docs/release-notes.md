This minor release of PowerPass updates the KeePassLib version to 2.60 and introduces some minor changes to the testing and deployment scripts.
* If you are upgrading from 2.x, please review the release notes for [PowerPass v3.0.1](https://github.com/chopinrlz/powerpass/releases/tag/v3.0.1) as there are breaking changes. Using the `Deploy-PowerPass.ps1` script will automatically upgrade your Locker to account for these changes.
* If you are upgrading from 1.x, **you will need to export your Locker before upgrading.** The 1.x Locker format is not backwards compatible with v2.x or v3.x. You will need to export then re-import your Locker to retain your secrets.
# Changelog
## KeePassLib 2.60
The KeePassLib version has been updated to the latest v2.60.
## Deployment Salt Cleanup
During deployment, the randomly generated salt `byte[]` was not erased from memory after use. To prevent this secret from residing in memory after deployment, the array is now refilled with random data [(see commit e7529de)](https://github.com/chopinrlz/powerpass/commit/e7529dea6177b171e706c341c1c25246c1e8fda4).
## Import Testing Verification
If you run the `Test-Import.ps1` script to test the import process for bringing KeePass 2 secrets into your PowerPass Locker, the script will generate errors if you do not run the script in Windows PowerShell using the DP API edition of PowerPass.
# Deployment
To install PowerPass:
1. Download this release below, download the source code for this release, or clone to repo (for a dev build).
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder if you plan to compile KeePass or use the DP API edition)
3. You will see a notice about your Locker being updated to the latest edition, or that it's already v3.x

For detailed information about deployment see the [Deployment](https://chopinrlz.github.io/powerpass/deployment) article in the online documentation.
# File Hashes
| Release                 | SHA256 Hash                                                        |
| ----------------------- | ------------------------------------------------------------------ |
| PowerPass-3.0.5.tar.gz  | `9C91A9C8DE4E196B48768E657970513748FE2702DFDD70023E7B3E0BD562BF7B` |
| PowerPass-3.0.5.zip     | `C2C7AB71AA940725B8FF0433587E69F0A12D991988C7FA4E346DE54F2EC89482` |

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [How It Works](https://chopinrlz.github.io/powerpass/readme-cont) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Roadmap](https://chopinrlz.github.io/powerpass/roadmap) | [Usage](https://chopinrlz.github.io/powerpass/usage)