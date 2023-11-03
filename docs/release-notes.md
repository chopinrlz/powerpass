The latest release of PowerPass version 1.2.0 fixes a minor issue with the deployment script and makes deployment more defensive if you run it multiple times. The salt generation routine has been integrated into the deployment script.

## Features
### Support for KeePass Databases
Fetch secrets from KeePass databases using the `Open-PowerPassDatabase` and `Get-PowerPassSecret` cmdlets.
### Support for PowerPass Lockers
User-specific encrypted databases created with PowerPass natively and managed for you automatically. Simply use the `Read-PowerPassSecret` and `Write-PowerPassSecret` cmdlets after deploying the module to securely store and retrieve secrets with PowerPass natively.

## Deployment
To install:
1. Download the source code for this release
2. Run `Deploy-PowerPass.ps1` in Windows PowerShell

You must now use the `Deploy-PowerPass.ps1` script to deploy PowerPass. This release does not include a binary release because it must be deployed using the deployment script. For details on deployment please refer to the `README` on the homepage of this repository [here](https://github.com/chopinrlz/powerpass).

## Best Practices
NOTE: It is NOT recommended to install PowerPass for both the current user AND for all users since each deployment includes a unique random salt for encryption. If the module is deployed for all users, it may conflict with the user-level deployment.  The best practice is to deploy PowerPass once for each user who needs it.

## Known Issues
### [Non-script relative path references in deploy script](https://github.com/chopinrlz/powerpass/issues/1)
Workaround: run `Deploy-Module.ps1` from the directory where is it located.