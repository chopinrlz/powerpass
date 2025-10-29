# Usage
#### _Revised: October 29, 2025_
Service accounts and other non-interactive logins can access credentials you store for them.
And of course you can always use PowerPass with your own login, too.
Login to the system with your account, or the service account you use for automation, deploy PowerPass, and use `Write-PowerPassSecret` to store a credential for that account.
Keep in mind that you should NOT be using `Run as administrator` in Windows when interfacing with PowerPass.

### **_The credentials you store while logged in will only be accessible to that same account._**

The PowerPass module, Lockers, keys, and salts are all contained within the user's profile directory and everything is encrypted.
On the AES edition you can now change where your Locker and key are stored to place them on external storage or remote locations.
The [How It Works](https://chopinrlz.github.io/powerpass/readme-cont) article explains the technical workings in detail.
To incorporate PowerPass into your scritps and modules, follow these examples.

## Reading and Writing Secrets
* To read a secret from PowerPass use the `Read-PowerPassSecret` cmdlet.
* To write a secret into PowerPass use the `Write-PowerPassSecret` cmdlet.
* To remove a secret from PowerPass use the `Remove-PowerPassSecret` cmdlet.
* To import secerts from KeePass 2 use the `Import-PowerPassSecrets` cmdlet. _(DP API edition only)_

## Reading and Writing Files
* To get the list of files in PowerPass use the `Get-PowerPassAttachments` cmdlet.
* To read a file from PowerPass use the `Read-PowerPassAttachment` cmdlet.
* To write a file into PowerPass use the `Write-PowerPassAttachment` cmdlet.
* To remove a file from PowerPass use the `Remove-PowerPassAttachment` cmdlet.
* To add multiple files to PowerPass at once from disk use the `Add-PowerPassAttachment` cmdlet.
* To export multiple files from PowerPass back to disk use the `Export-PowerPassAttachment` cmdlet.

## Back Up, Restore, and Maintenance
* To export a copy of all your secrets and files use the `Export-PowerPassLocker` cmdlet.
* To import secrets and files previously exported use the `Import-PowerPassLocker` cmdlet.
* To erase all secrets and files from PowerPass use the `Clear-PowerPassLocker` cmdlet.
* To rotate your PowerPass Locker keys use the `Update-PowerPassKey` cmdlet.
* To change where your Locker is stored use the `Set-PowerPass` cmdlet. _(AES edition only)_

## Utilities
* To generate a random password use the `New-PowerPassRandomPassword` cmdlet.
* To get PowerPass information use the `Get-PowerPass` cmdlet.

## Full Cmdlet Reference
1. For the AES edition: [PowerPass AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref)
2. For the DP API edition: [PowerPass DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref)

# Getting Secrets from KeePass 2
* To open a KeePass 2 database use the `Open-PowerPassDatabase` cmdlet. _(DP API edition only)_
* Pipe or pass the output to `Get-PowerPassSecret` to fetch secrets from the KeePass 2 database. _(DP API edition only)_

## Storing KeePass 2 Database Passwords in PowerPass
* To import secerts from KeePass 2 into PowerPass use the `Import-PowerPassSecrets` cmdlet. _(DP API edition only)_

# Use Case: Automating Access to Active Directory
One of the most common scenarios is automating access to Active Directory.
Configuring a script to run with Domain Admin permissions is risky as the script must have access to highly privileged credentials.
To ensure these credentials are not compromised, you can store them with PowerPass in an encrypted locker.

### Setup the PowerPass Locker
1. First, determine which `logon account` you plan to use to run the script.
2. Login to the computer with this account and deploy `PowerPass` using the `Deploy-PowerPass.ps1` script provided with the release.
3. Using the `Write-PowerPassSecret` cmdlet, write the credentials into the locker using a distinct `Title` to recall them later.
4. Close PowerShell and log off.

For detailed instructions on how to store and retrieve Active Directory Domain credentials with PowerPass, please see the [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) article.
Now that you have credentials in your locker, you can use them in your script.

### Update your Script
1. Open your script in your favorite PowerShell editor.
2. Using the `Read-PowerPassSecret` cmdlet, fetch the credentials you stored earlier by selecting with the distinct `Title`.
3. Configure your script to run as the `logon account`.
4. When your script runs it will read the credentials from the encrypted PowerPass Locker.

See below for an example.

### Example
This code uses PowerPass to load Domain credentials from the logon account's PowerPass Locker:
```powershell
# Get the username and password as a PSCredential
$creds = Read-PowerPassSecret -Match "DEV Domain Admin" -AsCredential

# Call out to Active Directory with the credential
Get-ADUser -Credential $creds
```
To create the `PSCredential`, the secret must have a `UserName` and a `Password` property set.
If either property is blank, the operation may fail with an error.

All PowerPass topics can be found at the bottom of this page.
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [How It Works](https://chopinrlz.github.io/powerpass/readme-cont) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Roadmap](https://chopinrlz.github.io/powerpass/roadmap) | [Usage](https://chopinrlz.github.io/powerpass/usage)