# OneDrive Backup
#### _Revised: January 15, 2024_
## Overview
OneDrive Backup is a feature of OneDrive which automatically maps your local user profile folders to your OneDrive cloud share.
When you enable OneDrive Backup, PowerShell modules installed for your user profile are moved to a new location on disk and the `PSModulePath` environment variable is updated by OneDrive to reflect the change.
## Default Path
By default, user-specific PowerShell modules are deployed to `$env:USERPROFILE\Documents\WindowsPowerShell\Modules` which looks like `C:\Users\janedoe\Documents\WindowsPowerShell\Modules` on a default installation of Windows with a user profile on the `C:\` drive.
## OneDrive Backup Path
When you enable OneDrive Backup, the contents of your `$env:USERPROFILE\Documents` folder gets moved to `$env:ONEDRIVE\Documents` which looks like `C:\Users\janedoe\OneDrive\Documents` on a default installation of Windows with a user profile on the `C:\` drive for a personal OneDrive account.
As a result of this, OneDrive updates your `PSModulePath` and changes the default path to the OneDrive backup path.
## Where PowerPass is Deployed
PowerPass is always deployed to your **Default Path**, even if you have OneDrive Backup enabled.
PowerPass stores secrets in your local AppData folder which will never be backed up to OneDrive.
If you are using OneDrive Backup, and you want to use PowerPass, deploy PowerPass for your user profile then move it to your OneDrive Documents folder.
## How To Move PowerPass
In this example, Jane Doe is deploying PowerPass on her personal computer with OneDrive Backup enabled for her Documents folder.
1. Jane deploys PowerPass for herself which gets deployed to `C:\Users\janedoe\Documents\WindowsPowerShell\Modules\PowerPass`
2. She uses OneDrive Backup with her personal account
3. Jane moves the `PowerPass` folder from `C:\Users\janedoe\Documents\WindowsPowerShell\Modules` to `C:\Users\janedoe\OneDrive\Documents\WindowsPowerShell\Modules`

Jane's PowerPass installation will now be stored in the cloud in OneDrive.
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)