# Data Structures
#### _Revised: January 9, 2024_
PowerPass uses the `PSCustomObject` type to define several custom data structures suitable for storing and recalling your PowerShell Locker, its Secrets and Attachments, as well as KeePass 2 databases and their connection information.
## Lockers
Both the AES edition and the Data Protection API edition use the same data structures for common objects including:
1. Lockers
2. Locker Secrets
3. Locker Attachments  

These objects are initialized in the common module file `PowerPass.Common.ps1` found in the `/module` directory.
The PowerPass Locker is not an exposed data type.
However, for those who are curious, the Locker is a `PSCustomObject` with these properties.
It is serialized as JSON before being encrypted and converted to a base-64 encoded string for storage.
| Property | Data Type |
| -------- | --------- |
| 1. Secrets | PSCustomObject[] |
| 2. Attachments| PSCustomObject[] |
| 3. Created | System.DateTime (UTC) |
| 4. Modified | System.DateTime (UTC) |
### Property: Secrets
The `Secrets` property is an array of `PSCustomObject` items with Title, UserName, Password, URL, Notes, Expires, Created, and Modified fields. When you call the `Read-PowerPassSecret` cmdlet one or more of these objects are output to the pipeline for you. The Password is stored as a `SecureString` unless you specify the `-PlainTextPasswords` parameter in which case the password is returned from your Locker in plain-text as a `String`.
| Property | Data Type | Purpose |
| - | - | - |
|1. Title|String|The unique identifier of the Secret in your Locker|
|2. UserName|String|A place to store a username, such as an email address or login name|
|3. Password|SecureString or plain-text String|A place to store a password or secret key, use `-PlainTextPasswords` to retrieve in plain-text|
|4. URL|String|A place to store a URL such as a login URL or REST endpoint for reference|
|5. Notes|String|A place to store notes about the secret such as recovery codes or usage information|
|6. Expires|DateTime|A place to store an expiration date, such as for certificates which expire, or if credentials have limited time passwords that have to be changed, this can be used to keep track of when the password needs to be changed|
|7. Created|DateTime (UTC)|This is automatically set to the date and time when this secret was created|
|8. Modified|DateTime (UTC)|This is automatically set to the date and time the secret was last modified|
### Property: Attachments
The `Attachments` property is an array of `PSCustomObject` items with FileName, Data, Created, and Modified fields. Data is output to you as a byte array, but is stored in the Locker as a base-64 encoded string.
| Property | Data Type | Purpose |
| - | - | - |
| 1. FileName | String | The unique identifier of the attachment in your Locker, typically a filename |
| 2. Data | String | Base64-encoded string of the binary data of the attachment |
| 3. Created | DateTime (UTC) | This is automatically set to the date and time when this attachment was created |
| 4. Modified | DateTime (UTC) | This is automatically set to the date and time when this attachment was last modified |
### Property: Created
The `Created` property indicates when the Locker was created. This is stored in UTC.
### Property: Modified
The `Modified` property indicates when the Locker was last modified. This is stored in UTC.
## KeePass 2 Databases
The KeePass 2 database can only be opened by the Data Protection API edition of PowerPass which runs in Windows PowerShell 5.1.
This data structure is unique to KeePass 2 and the DP API implementation of PowerPass.
When you run the `Open-PowerPassDatabase` cmdlet, the output is a `PSCustomObject` with these properties.
1. Connector
2. Keys
3. LiteralPath
4. Secrets
5. StatusLogger
### Property: Connector
The `Connector` property contains the `KeePassLib.Serialization.IOConnectionInfo` instance which tells KeePassLib where to find the database on the local file system.
### Property: Keys
The `Keys` property contains the collection of keys required to open the database. In this case, for testing, it is only the one `KeePassLib.Keys.KcpPassword` key 12345 which is required.
### Property: LiteralPath
This is a string with the literal path of the database file on disk.
### Property: Secrets
This is the `KeePassLib.PwDatabase` instance from which you can access all the entries in the test database starting with the `RootGroup` property.
### Property: StatusLogger
The custom ```PowerPass.StatusLogger``` instance which KeePassLib writes to as it operates on the database file.
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)