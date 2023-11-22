# Incorporating PowerPass into your Scripts
PowerPass relies on the current user file system for security.
To incorporate PowerPass into you builds, follow these examples.
## Automating Access to Active Directory
One of the most common scenarios is automating access to Active Directory.
Configuring a script to run with Domain Admin permissions is risky as the script must have access to highly privileged credentials.
To ensure these credentials are not compromised, you can store them with PowerPass in an encrypted locker.
### Setup the PowerPass Locker
1. First, determine which `logon account` you plan to use to run the script.
2. Login to the computer with this account and deploy `PowerPass` using the `Deploy-PowerPass.ps1` script provided with the release.
3. Using the `Write-PowerPassSecret` cmdlet, write the credentials into the locker using a distinct `Title` to recall them later.
4. Close PowerShell and log off.
### Update your Script
1. Open your script in your favorite PowerShell editor.
2. Using the `Read-PowerPassSecret` cmdlet, fetch the credentials you stored earlier by selecting with the distinct `Title`.
3. Configure your script to run as the `logon account`.
4. When your script runs it will read the credentials from the encrypted PowerPass Locker.
### Example
This code uses PowerPass to load Domain credentials from the logon account's PowerPass Locker:
```powershell
# Get the username and password as a PSCredential
$creds = Read-PowerPassSecret -Match "DEV Domain Admin" -AsCredential

# Call out to Active Directory with the credential
Get-ADUser -Credential $creds
```