# Incorporating PowerPass into your Scripts
#### _Revised: January 26, 2024_
Service accounts and other non-interactive logins can access credentials you store for them.
And of course you can always user PowerPass with your own login, too.
Login to the system with your service account, deploy PowerPass, and use `Write-PowerPassSecret` to store a credential for that service account.

**The credentials you store while logged in as that service account will only be accessible to that same service account.**

The PowerPass module, Lockers, keys, and salts are all contained within the user's profile directory and everything is encrypted.
The [README](https://github.com/chopinrlz/powerpass?tab=readme-ov-file#powerpass) file explains all of this is detail.
To incorporate PowerPass into your scritps and modules, follow these examples.
## Automating Access to Active Directory
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
# Usage
For general usage of PowerPass, please see below.
## KeePass Databases
To open a KeePass database use the `Open-PowerPassDatabase` cmdlet.
Pipe or pass the output to `Get-PowerPassSecret` to fetch secrets from the KeePass database.
## PowerPass Locker
To read a secret from your PowerPass Locker use the `Read-PowerPassSecret` cmdlet.
To write a secret into your PowerPass Locker use the `Write-PowerPassSecret` cmdlet.
## Storing KeePass Database Passwords
If you are opening KeePass databases which use master passwords, you can store these passwords in your PowerPass Locker to keep them secure.
## Cmdlet Reference
1. For the AES edition: [PowerPass AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref)
2. For the DP API edition: [PowerPass DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref)

All PowerPass topics can be found at the bottom of this page.
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)