# PowerPass Cmdlet Reference for AES Implementation
#### _Revised: March 12, 2024_
The AES implementation of PowerPass works on Windows PowerShell and PowerShell 7 on Linux, MacOS, and Windows. These are the cmdlets:
1. [Add-PowerPassAttachment](#add-powerpassattachment)
2. [Clear-PowerPassLocker](#clear-powerpasslocker)
3. [Export-PowerPassAttachment](#export-powerpassattachment)
4. [Export-PowerPassLocker](#export-powerpasslocker)
5. [Get-PowerPass](#get-powerpass)
6. [Get-PowerPassAttachments](#get-powerpassattachments)
7. [Import-PowerPassLocker](#import-powerpasslocker)
8. [New-PowerPassRandomPassword](#new-powerpassrandompassword)
9. [Read-PowerPassAttachment](#read-powerpassattachment)
10. [Read-PowerPassSecret](#read-powerpasssecret)
11. [Remove-PowerPassAttachment](#remove-powerpassattachment)
12. [Remove-PowerPassSecret](#remove-powerpasssecret)
13. [Update-PowerPassKey](#update-powerpasskey)
14. [Write-PowerPassAttachment](#write-powerpassattachment)
15. [Write-PowerPassSecret](#write-powerpasssecret)

Here are the cmdlets for the AES implementation of PowerPass.
# Add-PowerPassAttachment
### SYNOPSIS
Adds files from the file system into your locker. The difference between `Add-PowerPassAttachment` and
`Write-PowerPassAttachment` is the Add amdlet is optimized for bulk adds from the pipeline using `Get-ChildItem`.
Also, the Add cmdlet does not prompt for a filename, but rather uses the filename, either the short name or
full path, of the file on disk as the filename in your locker.
Any files that already exist in your locker will be updated.
### PARAMETER FileInfo
One or more `FileInfo` objects collected from `Get-Item` or `Get-ChildItem`. Can be passed via pipeline.
### PARAMETER FullPath
If specified, the full file path will be saved as the file name.
### PARAMETER GZip
Enable GZip compression.
### EXAMPLE 1: Save All the Files in the Current Directory
In this example we load all the files from the current directory into our locker.
```powershell
# Add all the files in the current directory as attachments with just the filename as the stored filename
Get-ChildItem | Add-PowerPassAttachment
```
Note that directories will be ignored.
### EXAMPLE 2: Save All the Files in the Current Directory with the Full Path
In this example we load all the files from the current directory into our locker using the full path
from the location on disk as the filename.
```powershell
# Add all the file in the current directory as attachments with the full path as the stored filename
Get-ChildItem | Add-PowerPassAttachment -FullPath
```
### EXAMPLE 3: Save All the Files in the Current Directory with the Full Path and Compress each File
In this example we load all the files from the current directory into our locker using the full path
from the location on disk as the filename and we enable GZip compression for each file.
```powershell
# Add all the file in the current directory as attachments with the full path as the stored filename
Get-ChildItem | Add-PowerPassAttachment -FullPath -GZip
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
### NOTES
Rather than using Write-PowerPassAttachment, you can use Add-PowerPassAttachment to add multiple files
to your locker at once by piping the output of Get-ChildItem to Add-PowerPassAttachment. Each file fetched
by Get-ChildItem will be added to your locker using either the file name or the full path.
# Clear-PowerPassLocker
### SYNOPSIS
Deletes all your locker secrets and your locker key. PowerPass will generate a new locker and key
for you the next time you write or read secrets to or from your locker.
### PARAMETER Force
WARNING: If you specify Force, your locker and salt will be removed WITHOUT confirmation.
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# Export-PowerPassAttachment
### SYNOPSIS
Exports one or more attachments from your locker.
### PARAMETER FileName
The filename of the attachment to fetch. Supports wildcard matching.
### PARAMETER Path
The Path to the directory to output the file(s). Overrides LiteralPath.
### PARAMETER LiteralPath
The LiteralPath to the directory to output the file(s).
### PARAMETER OriginalPath
An optional switch that, when specified, uses the path of the file in the locker,
assuming that file in the locker has a full path, otherwise the file will be
exported to the current directory. Cannot be combined with Path or LiteralPath.
### PARAMETER Force
An optional switch that will force-overwrite any existing files on disk.
### OUTPUTS
This cmdlet outputs the FileInfo for each exported file.
### EXAMPLE 1
In this example we export a specific attachment to a specified directory.
```powershell
# Export the certificate file
Export-PowerPassAttachment -FileName "private.pfx" -Path "C:\Secrets"
```
### EXAMPLE 2
In this example we export a set of attachments back to their original locations.
These attachments were loaded into our locker using `Add-PowerPassAttachment` with the `-FullPath` parameter specified.
```powershell
# Save our attachments back to their original location
Export-PowerPassAttachment -FileName "C:\Secrets\*" -OriginalPath
```
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
# Get-PowerPassAttachments
### SYNOPSIS
Exports all the attachments to a list so you can search for attachments and see what attachments are
in your locker without exposing the file data.
### OUTPUTS
Outputs each attachment from your locker including the FileName, Created date, and Modified date.
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
# Read-PowerPassAttachment
### SYNOPSIS
Reads an attachment from your locker.
### PARAMETER FileName
The filename of the attachment to fetch.
### PARAMETER Raw
An optional parameter that, when specified, will return the entire PSCustomObject for the attachment.
Cannot be combined with AsText or Encoding.
### PARAMETER AsText
An optional parameter that, when specified, will return the attachment data as a Unicode string. Cannot
be combined with Raw.
### PARAMETER Encoding
If `-AsText` is specified, you can optionally specify a specific encoding, otherwise the default encoding
Unicode is used since Unicode is the default encoding used when writing text attachments into your locker.
This parameter can be useful if you stored a text attachment into your locker from a byte array since the
contents of the file may be ASCII, UTF-8, or Unicode you can specify that with the `-Encoding` parameter.
### OUTPUTS
Outputs the attachment data in byte[] format, or the PSCustomObject if -Raw was specified, or a
string if -AsText was specified, or $null if no file was found matching the specified filename.
### EXAMPLE 1
In this example, we fetch a text file from our locker and convert it to a string using the UTF-8 encoding
ourselves. The call to `Read-PowerPassAttachment` returns a `[byte[]]`.
```powershell
# Get the readme file and convert it to a string
$bytes = Read-PowerPassAttachment -FileName "readme.txt"
$str = ([System.Text.Encoding]::UTF8).GetString( $bytes )
```
### EXAMPLE 2
In this example, we fetch a text file from our locker and have PowerPass convert it to a string using the
Unicode encoding, the default encoding for text-based attachments. This example will not work properly if
you write a UTF-8 text file attachment from a `[byte[]]` into your locker. In this case, follow Example 3.
```powershell
# Get the readme file and have PowerPass encode it as a string
$str = Read-PowerPassAttachment -FileName "readme.txt" -AsText
```
### EXAMPLE 3
In this example, we fetch a text file from our locker and have PowerPass convert it to a string using the
UTF-8 encoding. We use UTF-8 because, when we added the attachment we added it using the `[byte[]]` of the
file data itself, which is not encoded. Since we want the string back, we encode it to UTF-8 which is the
encoding of the original file.
```powershell
# Get the readme file as a UTF-8 string
$str = Read-PowerPassAttachment -FileName "readme.txt" -AsText -Encoding Utf8
```
### EXAMPLE 5
In this example, we fetch a binary file from our locker. Binary files are returned as `[byte[]]` objects.
```powershell
# Get a certificate file as binary data
$bin = Read-PowerPassAttachment -FileName "certificate.pfx"
```
Your PowerPass locker is a better place to store private key certificate files than sitting on the file system.
This is the most useful purpose for attachments, but you can store anything you want.
### EXAMPLE 6
In this example, we get the raw `PSCustomObject` back from PowerPass and check its properties.
File data for raw attachments is stored as base64-encoded text in the `Data` property.
```powershell
# Get the readme file as a raw PSCustomObject
Read-PowerPassAttachment -FileName "readme.txt" -Raw | Get-Member
```
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
# Remove-PowerPassAttachment
### SYNOPSIS
Removes an attachment from your locker.
### PARAMETER FileName
The filename of the attachment to remove from your locker.
### NOTES
The filename parameter can be passed from the pipeline. You can see what attachments are in your locker
by running [Get-PowerPassAttachments](#get-powerpassattachments). You are not prompted to remove attachments.
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
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# Update-PowerPassKey
### SYNOPSIS
Rotates the Locker key to a new random key.
### DESCRIPTION
As a routine precaution, key rotation is recommended as a best practice when dealing with sensitive,
encrypted data. When you rotate a key, PowerPass re-encrypts your PowerPass Locker with a new random
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
# Write-PowerPassAttachment
### SYNOPSIS
Writes an attachment into your locker.
### PARAMETER FileName
The name of the file to write into your locker. If this file already exists, it will be updated.
### PARAMETER Path
Specify the Path to a file on disk. Cannot be combined with other parameters.
### PARAMETER LiteralPath
Specify the LiteralPath to a file on disk. Cannot be combined with other parameters.
### PARAMETER Data
Specify the Data for the file in any format, or from the pipeline such as from Get-ChildItem.
See the examples below for how to use this parameter. Cannot be combined with other parameters.
### PARAMETER Text
Specify the contents of the file as a text string. Your attachment will be created with Unicode
text encoding. Cannot be combined with other parameters.
### PARAMETER GZip
Enable GZip compression. Can only be used with Path, LiteralPath, or Data if Data is a FileInfo object.
### NOTES
Data and Text in string format is encoded with Unicode. Data in PSCustomObject format is converted to JSON then
encoded with Unicode. Byte arrays and FileInfo objects are stored natively with Byte encoding. Data in any other
formats is converted to a string using the build-in .NET `ToString()` function then encoded with Unicode. To
fetch text back from your locker saved as attachments use the `-AsText` parameter of `Read-PowerPassAttachment`
to ensure the correct encoding is used.
### EXAMPLE 1
In this example we load a binary certificate file into our locker from a relative path.
```powershell
# Add a certificate file from the current folder
Write-PowerPassAttachment -FileName "certificate.pfx" -Path ".\cert.pfx"
```
### EXAMPLE 2
In this example we load a binary certificate file into our locker from a relative path and compress it
with GZip compression.
```powershell
# Add a certificate file from the current folder
Write-PowerPassAttachment -FileName "certificate.pfx" -Path ".\cert.pfx" -GZip
```
### EXAMPLE 3
In this example we local a binary certificate file into our locker from a literal path.
```powershell
# Add the certificate file from C:\Private into our locker
Write-PowerPassAttachment -FileName "certificate.pfx" -LiteralPath "C:\Private\cert.pfx"
```
### EXAMPLE 4
In this example we local a binary certificate file into our locker from a literal path and compress it
with GZip compression.
```powershell
# Add the certificate file from C:\Private into our locker
Write-PowerPassAttachment -FileName "certificate.pfx" -LiteralPath "C:\Private\cert.pfx" -GZip
```
### EXAMPLE 5
In this example we demonstrate using the `-Data` parameter to load a file from a byte array.
This isn't necessary, as the `-Path` and `-LiteralPath` parameters provider better options,
but this demonstrates the capability, for example if you are getting a `[byte[]]` from another
library.
```powershell
# Read cert.pfx into a byte array then save it as an attachment
[byte[]]$data = Get-Content ".\cert.pfx" -Encoding Byte
Write-PowerPassAttachment -FileName "certificate.pfx" -Data $data
```
Keep in mind you cannot do this in PowerShell 7 because `-Encoding Byte` is not an option.
Use the `-Path` or `-LiteralPath` parameters instead to save binary files as attachments.
### EXAMPLE 6
In this example we demonstrate using the `-Data` parameter from the pipeline. `Get-Item`
outputs a `FileInfo` object which PowerPass will process automatically for you. To do this
with multiple files, see [Add-PowerPassAttachment](#add-powerpassattachment) which is optimized
for multiple files coming from the pipeline.
```powershell
# Get the file info for cert.pfx and save it as an attachment
Get-Item ".\cert.pfx" | Write-PowerPassAttachment -FileName "certificate.pfx"
```
This example also supports the use of the `-GZip` parameter to enable GZip compression on the file.
```powershell
# Get the file info for cert.pfx and save it as an attachment
Get-Item ".\cert.pfx" | Write-PowerPassAttachment -FileName "certificate.pfx" -GZip
```
### EXAMPLE 7
In this example we demonstrate using the `-Data` parameter with `Get-Content` to save a text
file which is output by `Get-Content` as an `[object[]]` with hard returns removed. Keep in
mind that when you use `Read-PowerPassAttachment` to get the data back, the hard returns in
the returned attachment data may not match those in the original file because they are stripped
from the data by `Get-Content`.
```powershell
# Save the text file readme.txt as an attachment
Write-PowerPassAttachment -FileName "readme.txt" -Data (Get-Content ".\readme.txt")
```
### EXAMPLE 8
In this example we demonstrate using the `-Data` parameter to store a custom object as an
attachment. This is very useful if you want to save a complex object into your locker that
isn't a simple set of credentials.
```powershell
# Save a complex object as an attachment
$data = [PSCustomObject]@{
    Hello = "World!"
    MyArray = 1..5
}
Write-PowerPassAttachment -FileName "custom-data.json" -Data $data
```
### EXAMPLE 9
In this example we demonstrate using the `-Text` parameter to save a text file as an attachment
using the default encoding provided by PowerPass `Unicode`.
```powershell
# Save the LICENSE text file as an attachment
$license = Get-Content ".\LICENSE" -Raw
Write-PowerPassAttachment -FileName "license.txt" -Text $license
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# Write-PowerPassSecret
### SYNOPSIS
Writes one or more secrets into your PowerPass locker.
### PARAMETER Title
Mandatory.
The Title of the secret.
This is unique to your locker.
If you already have a secret in your locker with this Title, it will be updated, but only the parameters you specify will be updated.
Can be set from the pipeline by property name.
### PARAMETER UserName
Optional. Sets the UserName property of the secret in your locker.
Can be set from the pipeline by property name.
### PARAMETER Password
Optional. Sets the Password property of the secret in your locker.
Can be set from the pipeline by property name.
### PARAMETER URL
Optional. Sets the URL property of the secret in your locker.
Can be set from the pipeline by property name.
### PARAMETER Notes
Optional. Sets the Notes property of the secret in your locker.
Can be set from the pipeline by property name.
### PARAMETER Expires
Optional. Sets the Expires property of the secret in your locker.
Can be set from the pipeline by property name.
### PARAMETER MaskPassword
An optional switch that, when specified, will prompt you to enter a password rather than having to use the Password parameter.
### EXAMPLE 1: Saving a Secret with a UserName and Password
Most secrets are combinations of usernames and passwords.
In this example, we store a secret with a username and password we need to use later.
```powershell
# Store our new secret
Write-PowerPassSecret -Title "Domain Service Account" -UserName "DEV\svc_admin" -Password "jcnuetdghskfnrk"
```
NOTE: It is important that you close your PowerShell terminal if you do this to avoid leaving the password on-screen to avoid exposing the password to others.
You can also save a secret without having to specify the password as a parameter.
Using the `-MaskPassword` parameter, PowerPass will prompt you for a password and mask the input.
```powershell
# Store our new secret
PS> Write-PowerPassSecret -Title "Domain Service Account" -UserName "DEV\svc_admin" -MaskPassword
Enter the Password for the secret: *************
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
### EXAMPLE 4: Bulk Loading Multiple Secrets
In this example we show loading multiple secrets into your Locker from an external source in bulk.
When you load multiple secrets into your Locker, it is more efficient to pipeline the collection of secrets into the Locker.
The `Write-PowerPassSecret` cmdlet is optimized to load multiple records from the pipeline.
Loading them one at a time is many times slower.
In the code below, we import a CSV file and load its contents into the Locker.
```powershell
# Import the secrets from a CSV file
Import-Csv "MySecrets.csv" | Write-PowerPassSecret
```
Assuming the CSV file is formatting to include a Title, an optionally a UserName, Password, URL, and Notes field, you can pass the imported CSV file object directly via the pipeline to the `Write-PowerPassSecret` cmdlet.
### EXAMPLE 5: Bulk Loading Secrets from Custom Objects
You can also use `PSCustomObject` instances to load secrets one at a time or in bulk such as from an array of secrets loaded from elsewhere.
```powershell
# Declare a new secret
$mySecret = [PSCustomObject]@{
    Title = "My New Secret"
    UserName = "my_user_name"
    Password = "myPassword"
}
$mySecret | Write-PowerPassSecret
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-aes-implementation)***
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)