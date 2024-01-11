# PowerPass Cmdlet Reference for Windows PowerShell DP API / KeePass 2 Implementation
#### _Revised: January 11, 2024_
The Windows PowerShell Data Protection API implementation supports Windows PowerShell 5.1 and includes support for KeePass 2 databases as well as PowerPass Lockers. Cmdlets for this implementation are as follows:
1. [Clear-PowerPassLocker](#clear-powerpasslocker)
2. [Export-PowerPassLocker](#export-powerpasslocker)
3. [Import-PowerPassLocker](#import-powerpasslocker)
4. [Get-PowerPassSecret](#get-powerpasssecret)
5. [Get-PowerPass](#get-powerpass)
6. [New-PowerPassRandomPassword](#new-powerpassrandompassword)
7. [Open-PowerPassDatabase](#open-powerpassdatabase)
8. [Open-PowerPassTestDatabase](#open-powerpasstestdatabase)
9. [Read-PowerPassSecret](#read-powerpasssecret)
10. [Remove-PowerPassSecret](#remove-powerpasssecret)
11. [Update-PowerPassSalt](#update-powerpasssalt)
12. [Write-PowerPassSecret](#write-powerpasssecret)

Continue reading for the cmdlet details.
# Clear-PowerPassLocker
### SYNOPSIS
Deletes all your locker secrets.
### DESCRIPTION
If you want to delete your locker secrets and start with a clean locker, you can use thie cmdlet to do so.
When you deploy PowerPass using the Deploy-Module.ps1 script provided with this module, it generates a
unique salt for this deployment which is used to encrypt your locker's salt. If you replace this salt by
redeploying the module, you will no longer be able to access your locker and will need to start with a
clean locker.
### PARAMETER Force
WARNING: If you specify Force, your locker and salt will be removed WITHOUT confirmation.
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
# Export-PowerPassLocker
### SYNOPSIS
Exports your PowerPass Locker to an encrypted backup file powerpass_locker.bin.
### DESCRIPTION
You will be prompted to enter a password.
### PARAMETER Path
The path where the exported file will go. This is mandatory, and this path must exist.
### OUTPUTS
This cmdlet does not output to the pipeline. It creates the file powerpass_locker.bin
in the target Path. If the file already exists, you will be prompted to replace it.
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
# Import-PowerPassLocker
# SYNOPSIS
Imports an encrypted PowerPass locker created from Export-PowerPassLocker.
### DESCRIPTION
You can import a PowerPass locker including all the locker secrets and attachments from an exported copy.
You can import any locker, either from the AES edition or the DP API edition of PowerPass.
You will be prompted to enter the password to the locker.
### PARAMETER LockerFilePath
The path to the locker file on disk. This is mandatory.
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
# Get-PowerPassSecret
### SYNOPSIS
Retrieves secrets from a KeePass 2 database opened with `Open-PowerPassDatabase`.
### DESCRIPTION
This cmdlet will extract and decrypt the secrets stored in a KeePass 2 database which was opened using
the `Open-PowerPassDatabase` cmdlet. An optional `Match` parameter can be specified to limit the secrets found
to those which match the query, or which match the text exactly.
### INPUTS
This cmdlet will accept the output from `Open-PowerPassDatabase` as pipeline input.
### OUTPUTS
This cmdlet will output all, or each matching secret in the PowerPass database. Each secret is a `PSCustomObject`
with the following properties:
```
1. Title    = the Title or display name of the secret as it appears in KeePass 2
2. UserName = the username field value
3. Password = the password field value, as a SecureString by default, or plain-text if specified
4. URL      = the URL field value
5. Notes    = the Notes field value
6. Expires  = the Expires field value
```
Each entry in the KeePass 2 database is output to the pipeline not including the groups.
### PARAMETER Database
The PowerPass database opened using `Open-PowerPassDatabase`. This can be passed via pipeline.
### PARAMETER Match
An optional match filter. If this is specified, this cmdlet will only output secrets where the Title
matches this filter. Use * for wildcards, use ? for single characters, or specify an exact Title for
an exact match. If this is not specified, all secrets will be returned.
### PARAMETER PlainTextPasswords
An optional switch which will cause this cmdlet to output secrets with plain-text passwords. By default,
passwords are returned as SecureString objects.
### EXAMPLE 1: Get All Secrets
In this example we demonstrate getting all the secrets from a KeePass 2 database.
The hierarchy of the KeePass 2 database is not maintained.
All secrets are returned as a flat array.
```powershell
# Open the KeePass 2 database
$db = Open-PowerPassDatabase -Path "C:\Secrets\KeePassDb.kdbx" -WindowsUserAccount

# Get all the secrets and output their titles
$secrets = Get-PowerPassSecret -Database $db
foreach( $secret in $secrets ) {
    Write-Host $secret.Title
}
```
### EXAMPLE 2: Getting Secrets with Pipeline Filtering
In this example we demonstrate pipeline filtering to fetch secrets.
While this method works, it is not recommended as it returns more data than may be required.
```powershell
# Open the KeePass 2 database
$db = Open-PowerPassDatabase -Path "C:\Secrets\KeePassDb.kdbx" -WindowsUserAccount

# Get the Domain Service Account secret
$secret = Get-PowerPassSecret -Database $db | ? Title -eq "Domain Service Account"
```
### EXAMPLE 3: Getting Secrets with Match Filtering
In this example we demonstrate match filtering to fetch secrets.
This method is the most efficient for locating secrets in a KeePass 2 database.
Only secrets which match the filter by Title will be returned.
You can use wildcards or RegEx syntax.
```powershell
# Open the KeePass 2 database
$db = Open-PowerPassDatabase -Path "C:\Secrets\KeePassDb.kdbx" -WindowsUserAccount

# Get the Domain Service Account secret
$secret = Get-PowerPassSecret -Database $db -Match "Domain Service Account"
```
### EXAMPLE 4: Using the Pipeline
In this example, we demonstrate using the pipeline to get a secret with a single line.
```powershell
# Get a secret with one line
$secret = "C:\Secrets\KeePassDb.kdbx" | Open-PowerPassDatabase -WindowsUserAccount | Get-PowerPassSecret -Match "Domain Service Account"
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
# Get-PowerPass
### SYNOPSIS
Gets all the information about this PowerPass deployment.
### OUTPUTS
This cmdlet outputs a PSCustomObject with the following properties:
```
1.  KeePassLibraryPath = The absolute path to the KeePassLib.dll used by PowerPass
2.  KeePassLibAssembly = A [System.Reflection.Assembly] object of KeePassLib
3.  TestDatabasePath   = The absolute path of the test KeePass 2 database
4.  StatusLoggerSource = The absolute path to the StatusLogger class source code
5.  ExtensionsSource   = The absolute path to the Extensions class source code
6.  ModuleSaltFilePath = The absolute path to the module's salt file
7.  LockerFolderPath   = The absolute path to the folder where PowerPass stores your Locker
8.  LockerFilePath     = The absolute path to your Locker file
9.  LockerSaltPath     = The absolute path to your Locker's salt file
10. Implementation     = The type of implementation either "DPAPI" or "AES", in this case "DPAPI"
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
# New-PowerPassRandomPassword
### SYNOPSIS
Generates a random password from all available standard US 101-key keyboard characters.
### PARAMETER Length
The length of the password to generate. Can be between 1 and 65536 characters long. Defaults to 24.
### OUTPUTS
Outputs a random string of typable characters to the pipeline which can be used as a password.
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
# Open-PowerPassDatabase
### SYNOPSIS
Opens a KeePass 2 database file.
### DESCRIPTION
This cmdlet will open a KeePass 2 database file from the given path using the keys specified by the given
parameters. This cmdlet will then create a PSCustomObject containing the KeePass database in-memory
along with the metadata about the database including its location on disk, log events from KeePass, and
the collection of keys required to open it. You can then pipe or pass the output of this cmdlet to the
Get-PowerPassSecret cmdlet to extract the encrypted secrets.
### PARAMETER Path
The path on disk to the KeePass file.
### PARAMETER MasterPassword
If the KeePass 2 database uses a master password, include that here.
### PARAMETER KeyFile
If the KeePass 2 database uses a key file, include the path to the key file here.
### PARAMETER WindowsUserAccount
If the KeePass 2 database uses the Windows user account, include this switch.
### INPUTS
This cmdlet does not take any pipeline input.
### OUTPUTS
This cmdlet outputs a `PSCustomObject` containing the KeePass 2 database secrets. Pipe or pass this to
`Get-PowerPassSecret` to extract the secrets from the database.
### EXAMPLE 1: Open a KeePass 2 Database with a Password (Insecure)
In this example, we demonstrate how to open a KeePass 2 database using a password in plain-text.
This method is not secure, because the database password is visible, but is here for demonstration purpose.
```powershell
#
# This example shows how to open a KeePass database which uses a master password as a key
# NOTE: This method is inherently insecure if you embed the password for the database into
#       your PowerShell script itself. It is more secure to fetch a secure string from a
#       separate location or use PowerPass to store this secret in your Locker or in a
#       separate KeePass database protected with your Windows user account.
#

$pw = ConvertTo-SecureString -String "databasePasswordHere" -AsPlainText -Force
$db = Open-PowerPassDatabase -Path "C:\Secrets\MyKeePassDatabase.kdbx" -MasterPassword $pw
```
### EXAMPLE 2: Open a KeePass 2 Database with a Password (Secure)
In this example, we demonstrate using the PowerPass Locker to fetch a KeePass 2 database password.
This method is more secure since the password for the database is stored in the encrypted PowerPass Locker.
```powershell
#
# This example shows how to open a KeePass database which uses a master password as a key
# where the master password is securely stored in your PowerPass Locker.
#

$sc = Read-PowerPassSecret -Match "My KeePass Database Password"
$db = Open-PowerPassDatabase -Path "C:\Secrets\MyKeePassDatabase.kdbx" -MasterPassword ($sc.Password)
```
### EXAMPLE 3: Open a KeePass 2 Database with a Key File
In this example we demonstrate opening a KeePass 2 database with a KeePass key file.
```powershell
#
# This example shows how to open a KeePass database which uses a key file.
# NOTE: You should always store the key file in a safe place like your user profile folder
#       which can only be accessed by yourself and any local administrators on the computer.
#

$db = Open-PowerPassDatabase -Path "C:\Secrets\MyKeePassDatabase.kdbx" -KeyFile "C:\Users\me\Documents\DatabaseKeyFile.keyx"
```
### EXAMPLE 4: Open a KeePass 2 Databae with your Windows User Account
In this example we demonstrate opening a KeePass 2 database with your Windows user account.
KeePass 2 databases support Windows Data Protection API encryption.
When you create your KeePass 2 database, you can elect to encrypt it with your Windows user account.
These databases can be opened using the `-WindowsUserAccount` parameter with `Open-PowerPassDatabase`.
```powershell
#
# This example shows how to open a KeePass database which uses your Windows user account.
# Securing a KeePass file with your Windows user account provides a very secure method for
# storing secrets because they can only be accessed by you on the local machine and no one
# else, not even local administrators or domain administrators. This method is recommended
# for storing passwords to other KeePass databases.
#

$db = Open-PowerPassDatabase -Path "C:\Secrets\MyKeePassDatabase.kdbx" -WindowsUserAccount
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
# Open-PowerPassTestDatabase
### SYNOPSIS
Opens the TestDatabase.kdbx database bundled with PowerPass for testing.
### DESCRIPTION
When you use Open-PowerPassTestDatabase the PowerPass module will load the
KeePass database TestDatabase.kdbx bundled with this module. By default,
this database contains one key requried to open it: the password 12345. You
can open this database in KeePass 2. It was originally created with KeePass 2.
The output from this cmdlet includes all the relevant properties and data
required to access and read data from KeePass databases. It also showcases
the standard PSCustomObject data structure utilized by the PowerPass module.
### INPUTS
This cmdlet has no inputs, but it depends on the TestDatabase.kdbx file bundled
with this module.
### OUTPUTS
This cmdlet outputs a PSCustomObject with these properties:
```
1. Secrets - the KeePassLib.PwDatabase instance which exposes the secrets contained within the test database
2. StatusLogger - the PowerPass.StatusLogger instance which captures logging messages from KeePassLib
3. LiteralPath - the absolute path to the test database on the local file system
4. Connector - the KeePassLib.IOConnectionInfo instance which tells KeePassLib where to find the test database
5. Keys - the collection of keys required to open the test database, in this case just the password key
```
Below is a code example for how to use this cmdlet.
### EXAMPLE
```powershell
# Open the test database file
$database = Open-PowerPassTestDatabase

# Fetch the root group, the KeePass 2 database starting point
$rootGroup = $database.Secrets.RootGroup

# Iterate the Entries property to peruse the KeePass 2 database
foreach( $entry in $rootGroup.Entries ) {

    # Echo the Title of each entry
    $entry.Strings | ? Key -eq "Title"
}
```
### NOTES
This function will fail if the test database file is not found in the module folder.
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
# Read-PowerPassSecret
### SYNOPSIS
Reads secrets from your PowerPass locker.
### PARAMETER Match
An optional filter. If specified, only secrets whose Title matches this filter are output to the pipeline.
Do not combine with Title as Title will be ignored if Match is specified.
### PARAMETER Title
An optional exact match filter. If specified, only the one secret with the Title specified will be returned.
Cannot be combined with Match as Title will be ignored if Match is specified.
### PARAMETER PlainTextPasswords
An optional switch which instructs PowerPass to output the passwords in plain-text. By default, all
passwords are output as SecureString objects. You cannot combine this with AsCredential.
### PARAMETER AsCredential
An optional switch which instructs PowerPass to output the secrets as a PSCredential object. You cannot
combine this with PlainTextPasswords.
### OUTPUTS
This cmdlet outputs PowerPass secrets from your locker to the pipeline. Each secret is a PSCustomObject
with these properties:
```
1. Title     - the name, or title, of the secret, this value is unique to the locker
2. UserName  - the username field string for the secret
3. Password  - the password field for the secret, by default a SecureString
4. URL       - the URL string for the secret
5. Notes     - the notes string for the secret
6. Expires   - the expiration date for the secret, by default December 31, 9999
7. Created   - the date and time the secret was created in the locker
8. Modified  - the date and time the secret was last modified
```
### NOTES
When you use PowerPass for the first time, PowerPass creates a default secret in your locker with the
Title "Default" with all fields populated as an example of the data structure stored in the locker.
You can delete or change this secret by using Write-PowerPassSecret or Delete-PowerPassSecret and specifying
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
To create the `PSCredential`, the secret must have a `UserName` and a `Password` property set.
If either property is blank, the operation may fail with an error.
```powershell
# Get all the Active Directory users
$svcAccount = Read-PowerPassSecret -Match "Domain Reader Service" -AsCredential
Get-ADUser -Credential $svcAccount
```
### EXAMPLE 5: Get a Specific Secret by Title
In this example we fetch a single secret by Title of a known secret we expect to be in our locker, one that was added earlier.
If the Title we specify is not found in the locker, nothing will be returned.
```powershell
# Get the secret with this exact Title
$sec = Read-PowerPassSecret -Title "Domain Admin Login"
```
### EXAMPLE 6: Get a Specific Secret as a Credential by Title
In this example we fetch a single secret as a `PSCredential` by Title of a known secret we expect to be in our locker.
If the Title we specify is not found in the locker, nothing will be returned.
To create the `PSCredential`, the secret must have a `UserName` and a `Password` property set.
If either property is blank, the operation may fail with an error.
```powershell
# Get the Domain Admin Login credential
$svcAccount = Read-PowerPassSecret -Title "Domain Admin Login" -AsCredential
Get-ADUser -Credential $svcAccount
```
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
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
# Update-PowerPassSalt
### SYNOPSIS
Rotates the Locker salt to a new random key.
### DESCRIPTION
As a reoutine precaution, key rotation is recommended as a best practice when dealing with sensitive,
encrypted data. When you rotate a key, PowerPass reencrypts your PowerPass Locker with a new Locker
salt. This ensures that even if a previous encryption was broken, a new attempt must be made if an
attacker regains access to your encrypted Locker.
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
# Write-PowerPassSecret
### SYNOPSIS
Writes a secret into your PowerPass locker.
### DESCRIPTION
Before you can read any secrets from your PowerPass locker you have to write them into your PowerPass locker.
Use the `Write-PowerPassSecret` cmdlet to write secrets into your encrypted PowerPass locker and fetch them later.
### PARAMETER Title
Mandatory. The Title of the secret. This is unique to your locker. If you already have a secret in your
locker with this Title, it will be updated, but only the parameters you specify will be updated.
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
Optional. Sets the Expiras property of the secret in your locker.
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
PS C:\Users\me> Write-PowerPassSecret -Title "Domain Service Account" -UserName "DEV\svc_admin" -MaskPassword
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
##### ***[Back to Top](#powerpass-cmdlet-reference-for-windows-powershell-dp-api--keepass-2-implementation)***
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)