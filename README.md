# PowerPass
A cross-platform PowerShell module for secret storage and retrieval on Linux, MacOS, and Windows.
PowerPass supports Windows PowerShell 5 and PowerShell 7.

## Purpose
PowerPass provides an easy to use set of cmdlets for securely storing and retrieving credentials automatically without user input and without external dependencies. In automated scenarios, there is no user present to type in a set of credentials.

1. PowerPass facilitates the use of credentials in automated scenarios.
2. PowerPass credentials are locked down so that only the user who stored them can access them.
3. PowerPass retrieves credentials automatically for the current user.
4. PowerPass does not require any user input when retrieving credentials.

## Features
PowerPass has the following features:

* Store and retrieve secrets (e.g. credentials, auth tokens, recovery codes)
* Search for secrets using pattern matching & wildcards
* Associate metadata with secrets (e.g. expiration date, general notes, URL)
* Fetch secrets in `PSCredential` format
* Retrieve secrets from KeePass 2 databases (Windows PowerShell-only)
* Store and retrieve files/attachments
* Compress stored files/attachment with GZip
* Export and import secrets and files to/from a backup file
* Import secrets from KeePass 2 into PowerPass
* Generate random passwords

All secrets and files stored by PowerPass are **encrypted** in a file called a Locker.
Only your user account can decrypt your Locker.

## Why Use PowerPass?
There are various secret storage and management tools available to you.
So why use PowerPass?

* It's free
* It's fully open-source
* It's automated
* It does not require Internet access
* It does not depend on any modules
* It requires zero configuration
* It works on multiple operating systems
* It uses standard encryption algorithms

# Deployment and Usage
To install PowerPass:

1. Download a [release](https://github.com/chopinrlz/powerpass/releases) from the releases page or clone this repo.
2. Unzip/expand the release archive to a **writable** folder
3. Open any PowerShell terminal
4. Run `.\Deploy-PowerPass.ps1`

PowerPass will be available for immediate use after deployment.
Run `Get-PowerPass` to review your deployment details.

## Upgrading
Use the same `Deploy-PowerPass.ps1` script to upgrade to a new version.
The script will **NOT** overwrite your Locker or Locker keys if they already exist.
You can also do this to downgrade to an older release.

# Editions
PowerPass comes in four flavors and supports Linux, macOS, and Windows.
1. 256-bit AES Encryption
2. Windows Data Protection API
3. TPM Encryption (in development, see [Roadmap](https://chopinrlz.github.io/powerpass/roadmap))
4. Web Browser (in development, see [Roadmap](https://chopinrlz.github.io/powerpass/roadmap))

## Operating System Compatibility
| OS | AES | DPAPI | TPM | Web |
| - | - | - | - | - |
| Linux | X | - | X | X |
| macOS | X | - | - | X |
| Windows | X | X | - | X |

PowerPass works and is tested on every PowerShell edition including WinPS and PS7.

# More Information
1. For a list of cmdlets and other resources please reivew the [Online Documentation](https://chopinrlz.github.io/powerpass)
2. For more details on deployment please see [Deployment](https://chopinrlz.github.io/powerpass/deployment)
3. For technical details on how it works please see [How It Works](https://chopinrlz.github.io/powerpass/readme-cont)
4. For how to use PowerPass see [Usage](https://chopinrlz.github.io/powerpass/usage)
5. To view the roadmap of upcoming features see [Roadmap](https://chopinrlz.github.io/powerpass/roadmap)

# License and Copyright
PowerPass is copyright 2023-2025 by ShwaTech LLC.
PowerPass is open-source, free software. You may use PowerPass for any purpose.
PowerPass is licensed under the GNU Public License v2.0.
The license can be found in the [LICENSE](https://github.com/chopinrlz/powerpass/blob/main/LICENSE) file.
You may copy, modify, and distribute PowerPass for personal or commercial use under the terms of the GNU Public License v2.0.

# Repository Directory
The directory of assets in this repo can be found in the [REPO](https://github.com/chopinrlz/powerpass/blob/main/REPO.md) markdown file.