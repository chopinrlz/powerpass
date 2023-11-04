The latest release of PowerPass version 1.2.0 fixes a minor issue with the deployment script and makes deployment more defensive if you run it multiple times. The salt generation routine has been integrated into the deployment script.

## New Features
### Locker Export and Import
Using the new `Export-PowerPassLocker` and `Import-PowerPassLocker` cmdlets you can now make backup copies of your PowerPass locker secrets and restore them later. Locker secrets are encrypted using the Windows Data Protection API under the current user scope and can only be imported back onto the same machine with the same user profile. This is helpful if you want to deploy a new version of PowerPass, you can import your Locker secrets after the update.
### Release Includes KeePassLib
New releases of PowerPass will include a compiled assembly for KeePassLib bundled with the release. You can now deploy PowerPass without needing to compile KeePassLib from source although it is still an option.

## Features
### Support for KeePass Databases
Fetch secrets from KeePass databases using the `Open-PowerPassDatabase` and `Get-PowerPassSecret` cmdlets.
### Support for PowerPass Lockers
User-specific encrypted databases created with PowerPass natively and managed for you automatically. Simply use the `Read-PowerPassSecret` and `Write-PowerPassSecret` cmdlets after deploying the module to securely store and retrieve secrets with PowerPass natively.
### Clear Locker Secrets
Using the `Clear-PowerPassLocker` cmdlet you can clear all your Locker secrets. You will be prompted to confirm this action unless you specify the `Force` parameter.

## Deployment
To install:
1. Download the source code for this release
2. Run `Deploy-PowerPass.ps1` in Windows PowerShell

You must now use the `Deploy-PowerPass.ps1` script to deploy PowerPass. For details on deployment please refer to the `README` on the homepage of this repository [here](https://github.com/chopinrlz/powerpass).

## Best Practices
NOTE: It is NOT recommended to install PowerPass for both the current user AND for all users since each deployment includes a unique random salt for encryption. If the module is deployed for all users, it may conflict with the user-level deployment.  The best practice is to deploy PowerPass once for each user who needs it.

## Known Issues
### [OneDrive backup changes default PSModulePath](https://github.com/chopinrlz/powerpass/issues/2)
Please see the [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) article for more details.