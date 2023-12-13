# PowerPass Cmdlet Reference for AES Implementation
The AES implementation of PowerPass works on Windows PowerShell and PowerShell 7 on Linux, MacOS, and Windows.
1. [Clear-PowerPassLocker](#clear-powerpasslocker)
2. [Export-PowerPassLocker](#export-powerpasslocker)
3. [Get-PowerPass](#get-powerpass)
4. [Import-PowerPassLocker](#import-powerpasslocker)
5. [New-PowerPassRandomPassword](#new-powerpassrandompassword)
6. [Read-PowerPassSecret](#read-powerpasssecret)
7. [Remove-PowerPassSecret](#remove-powerpasssecret)
8. [Update-PowerPassKey](#update-powerpasskey)
9. [Write-PowerPassSecret](#write-powerpasssecret)

Here are the cmdlets for the AES implementation of PowerPass.
# Clear-PowerPassLocker
### SYNOPSIS
Deletes all your locker secrets and your locker key. PowerPass will generate a new locker and key
for you the next time you write or read secrets to or from your locker.
### PARAMETER Force
WARNING: If you specify Force, your locker and salt will be removed WITHOUT confirmation.
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# Export-PowerPassLocker
### SYNOPSIS
Exports your PowerPass Locker to an encrypted backup file named `powerpass_locker.bin` in the directory
specified by the `Path` parameter.
### DESCRIPTION
You will be prompted to enter a password to encrypt the locker. The password must be
between 4 and 32 characters.
### PARAMETER Path
The path where the exported file will go. This is mandatory, and this path must exist.
### OUTPUTS
This cmdlet does not output to the pipeline. It creates the file `powerpass_locker.bin`
in the target `Path`. If the file already exists, you will be prompted to replace it.
### EXAMPLE
In this example, we backup our Locker and key to a USB drive mounted as the E: drive.
```powershell
# Backup my locker and key to a USB drive
Export-PowerPassLocker -Path "E:\" -Password "mySecretPassphrase"
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# Get-PowerPass
### SYNOPSIS
Gets all the information about this PowerPass deployment.
### OUTPUTS
A PSCustomObject with these properties:
* AesCryptoSourcePath : The path on disk to the AesCrypto.cs source code
* LockerFolderPath    : The folder where your locker is stored
* LockerFilePath      : The absolute path to your PowerPass locker on disk
* LockerKeyFolderPath : The folder where your locker key is stored
* LockerKeyFilePath   : The absolute path to your PowerPass locker key file
* Implementation      : The implementation you are using, either AES or DPAPI

You can access these properties after assigning the output of `Get-PowerPass` to a variable.
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# Import-PowerPassLocker
### SYNOPSIS
Imports a PowerPass locker file.
### DESCRIPTION
You will be prompted to enter the locker password.
### PARAMETER LockerFile
The path to the locker file on disk to import.
### PARAMETER Force
Import the locker files without prompting for confirmation.
### EXAMPLE
In this example, we import a Locker file which will overwrite your existing Locker file if you have one.
```powershell
# Import my old locker file
Import-PowerPassLocker -LockerFile "E:\Backup\powerpass_locker.bin" -Password "mySecretPassphrase"
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# New-PowerPassRandomPassword
### SYNOPSIS
Generates a random password from all available standard US 101-key keyboard characters.
### PARAMETER Length
The length of the password to generate. Can be between 1 and 65536 characters long. Defaults to 24.
### OUTPUTS
Outputs a random string of typable characters to the pipeline which can be used as a password.
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# Read-PowerPassSecret
### SYNOPSIS
Reads secrets from your PowerPass locker.
### PARAMETER Match
An optional filter. If specified, only secrets whose Title matches this filter are output to the pipeline.
Cannot be combined with Title as Title will be ignored if Match is specified.
### PARAMETER Title
An optional exact match filter. If specified, only the secret which exactly matches the Title will be
output to the pipeline. Do not combine with Match as Title will be ignored if Match is specified.
### PARAMETER PlainTextPasswords
An optional switch which instructs PowerPass to output the passwords in plain-text. By default, all
passwords are output as `SecureString` objects. You cannot combine this with `-AsCredential`.
### PARAMETER AsCredential
An optional switch which instructs PowerPass to output the secrets as `PSCredential` objects. You cannot
combine this with `-PlainTextPasswords`.
### OUTPUTS
This cmdlet outputs PowerPass secrets from your locker to the pipeline. Each secret is a PSCustomObject
with these properties:
1. Title     - the name, or title, of the secret, this value is unique to the locker
2. UserName  - the username field string for the secret
3. Password  - the password field for the secret, by default a SecureString
4. URL       - the URL string for the secret
5. Notes     - the notes string for the secret
6. Expires   - the expiration date for the secret, by default December 31, 9999
7. Created   - the date and time the secret was created in the locker
8. Modified  - the date and time the secret was last modified

You can access these properties after assigning the output to a variable.
### NOTES
When you use PowerPass for the first time, PowerPass creates a default secret in your locker with the
Title "Default" with all fields populated as an example of the data structure stored in the locker.
You can delete or change this secret by using `Write-PowerPassSecret` or `Delete-PowerPassSecret` and specifying
the Title of "Default".
### EXAMPLE 1: Get All the Secrets from your Locker
Calling the cmdlet by itself will output all your Locker secrets.
```powershell
# Get all my locker secrets
$secrets = Read-PowerPassSecret
foreach( $s in $secrets ) {
    $s.Title
}
```
### EXAMPLE 2: Get a Specific Secret from your Locker
Rather than fetching everything, you can use a match to fetch one or more secrets where the `Title` of the secret matches the filter you provide.
You can incorporate wildcards or RegEx in your `Match` parameter to get the secrets by exact title or by pattern.
```powershell
# Find all the domain logins
$domainLogins = Read-PowerPassSecret -Match "Domain Account for *"
foreach( $s in $domainLogins ) {
    $s.Title
}
```
### EXAMPLE 3: Get a Secret with the Password in Plain Text
There may be an occasion where you need the `Password` property in plain-text.
A common example of this is when you need a Client ID and Client Secret for app-based authentication.
```powershell
# Get the secret in plain-text
$s = Read-PowerPassSecret -Match "My Client App" -PlainTextPasswords
$clientId = $s.UserName
$clientSecret = $s.Password
```
### EXAMPLE 4: Get a Secret in PSCredential Format
Many PowerShell cmdlets which require authentication support the PSCredential format.
You can fetch a secret from your locker in this format automatically and pass it directly to the other cmdlet.
```powershell
# Get all the Active Directory users
$svcAccount = Read-PowerPassSecret -Match "Domain Reader Service" -AsCredential
Get-ADUser -Credential $svcAccount
```
### EXAMPLE 5: Get a Secret by Exact Title
In this example we fetch a secret using an exact Title match which we expect to find in our locker.
If no secret matching the Title is found, nothing is returned.
```powershell
# Get a specific secret from the locker
$sec = Read-PowerPassSecret -Title "Domain Admin Account"
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# Remove-PowerPassSecret
### SYNOPSIS
Removes a secret from your locker.
### PARAMETER Title
The Title of the secret to remove from your locker.
### NOTES
The Title parameter can be passed from the pipeline.
### EXAMPLE 1: Remove a Secret
In this example we demonstrate removing a single secret from the Locker.
```powershell
# Remove the Domain Admin credentials
Remove-PowerPassSecret -Title "Domain Admin Login"
```
### EXAMPLE 2: Remove a Few Secrets
In this example we demonstrate removing several secrets from the Locker at once.
```powershell
# Remove all the service accounts
"svc_sqlserver","svc_sharepoint","svc_spadmin" | Remove-PowerPassSecret
```
# Update-PowerPassKey
### SYNOPSIS
Rotates the Locker key to a new random key.
### DESCRIPTION
As a reoutine precaution, key rotation is recommended as a best practice when dealing with sensitive,
encrypted data. When you rotate a key, PowerPass reencrypts your PowerPass Locker with a new random
key. This ensures that even if a previous encryption was broken, a new attempt must be made if an
attacker regains access to your encrypted Locker.
### USAGE
The `Update-PowerPassKey` cmdlet runs without parameters.
Simply execute it and PowerPass with rotate your locker key.
```powershell
# Rotate my locker key
Update-PowerPassKey
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# Write-PowerPassSecret
### SYNOPSIS
Writes a secret into your PowerPass locker.
### PARAMETER Title
Mandatory.
The Title of the secret.
This is unique to your locker.
If you already have a secret in your locker with this Title, it will be updated, but only the parameters you specify will be updated.
### PARAMETER UserName
Optional. Sets the UserName property of the secret in your locker.
### PARAMETER Password
Optional. Sets the Password property of the secret in your locker.
### PARAMETER URL
Optional. Sets the URL property of the secret in your locker.
### PARAMETER Notes
Optional. Sets the Notes property of the secret in your locker.
### PARAMETER Expires
Optional. Sets the Expiras property of the secret in your locker.
### EXAMPLE 1: Saving a Secret with a UserName and Password
Most secrets are combinations of usernames and passwords.
In this example, we store a secret with a username and password we need to use later.
```powershell
# Store our new secret
Write-PowerPassSecret -Title "Domain Service Account" -UserName "DEV\svc_admin" -Password "jcnuetdghskfnrk"
```
### EXAMPLE 2: Saving a Secret with a Random Password
You can completely avoid typing a password for a secret if you use the password generator.
In this example, we create a new secret with a username and a randomly generated password.
The password will not be shown on the screen nor will we have to type it in.
```powershell
# Create a new credential with a random password
Write-PowerPassSecret -Title "Domain Service Account" -UserName "DEV\svc_admin" -Password (New-PowerPassRandomPassword)
```
### EXAMPLE 3: Adding Metadata to an Existing Secret
You can add secrets, and you can also update them with additional information.
In this example, we add some addition information to our `Domain Service Account` secret.
```powershell
# Add some more info to our Domain Service Account
Write-PowerPassSecret -Title "Domain Service Account" -URL "https://intranet.dev.local" -Notes "Use this account to access AD" -Expires ((Get-Date).AddDays(90))
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)