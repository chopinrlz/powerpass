# Data Structures
#### _Revised: May 5, 2024_
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

<table>
<tr><th width="30%">Property Name</th><th>Data Type</th></tr>
<tr><td width="30%">1. Secrets</td><td>PSCustomObject[]</td></tr>
<tr><td width="30%">2. Attachments</td><td>PSCustomObject[]</td></tr>
<tr><td width="30%">3. Created</td><td>System.DateTime (UTC)</td></tr>
<tr><td width="30%">4. Modified</td><td>System.DateTime (UTC)</td></tr>
</table>

### Property: Secrets
The `Secrets` property is an array of `PSCustomObject` items with Title, UserName, Password, URL, Notes, Expires, Created, and Modified fields. When you call the `Read-PowerPassSecret` cmdlet one or more of these objects are output to the pipeline for you. The Password is stored as a `SecureString` unless you specify the `-PlainTextPasswords` parameter in which case the password is returned from your Locker in plain-text as a `String`.

<table>
<tr><th width="30%">Property Name</th><th>Data Type</th><th>Purpose</th></tr>
<tr><td width="30%">1. Title</td><td>String</td><td>The unique identifier of the Secret in your Locker</td></tr>
<tr><td width="30%">2. UserName</td><td>String</td><td>A place to store a username, such as an email address or login name</td></tr>
<tr><td width="30%">3. Password</td><td>SecureString or plain-text String</td><td>A place to store a password or secret key, use `-PlainTextPasswords` to retrieve in plain-text</td></tr>
<tr><td width="30%">4. URL</td><td>String</td><td>A place to store a URL such as a login URL or REST endpoint for reference</td></tr>
<tr><td width="30%">5. Notes</td><td>String</td><td>A place to store notes about the secret such as recovery codes or usage information</td></tr>
<tr><td width="30%">6. Expires</td><td>DateTime</td><td>A place to store an expiration date, such as for certificates which expire, or if credentials have limited time passwords that have to be changed, this can be used to keep track of when the password needs to be changed</td></tr>
<tr><td width="30%">7. Created</td><td>DateTime (UTC)</td><td>This is automatically set to the date and time when this secret was created</td></tr>
<tr><td width="30%">8. Modified</td><td>DateTime (UTC)</td><td>This is automatically set to the date and time the secret was last modified</td></tr>
</table>

### Property: Attachments
The `Attachments` property is an array of `PSCustomObject` items with FileName, Data, Created, and Modified fields. Data is output to you as a byte array, but is stored in the Locker as a base-64 encoded string.

<table>
<tr><th width="30%">Property Name</th><th>Data Type</th><th>Purpose</th></tr>
<tr><td width="30%">1. FileName</td><td>String</td><td>The unique identifier of the attachment in your Locker, typically a filename</td></tr>
<tr><td width="30%">2. Data</td><td>String</td><td>Base64-encoded string of the binary data of the attachment</td></tr>
<tr><td width="30%">3. Created</td><td>DateTime (UTC)</td><td>This is automatically set to the date and time when this attachment was created</td></tr>
<tr><td width="30%">4. Modified</td><td>DateTime (UTC)</td><td>This is automatically set to the date and time when this attachment was last modified</td></tr>
</table>

### Property: Created
The `Created` property indicates when the Locker was created. This is stored in UTC.
### Property: Modified
The `Modified` property indicates when the Locker was last modified. This is stored in UTC.
## KeePass 2 Databases
The KeePass 2 database can only be opened by the Data Protection API edition of PowerPass which runs in Windows PowerShell 5.1.
This data structure is unique to KeePass 2 and the DP API implementation of PowerPass.
When you run the `Open-PowerPassDatabase` cmdlet, the output is a `PSCustomObject` with these properties.

<table>
<tr><th width="30%">Property Name</th><th>Description</th></tr>
<tr><td width="30%">1. Connector</td><td>The <code>Connector</code> property contains the <code>KeePassLib.Serialization.IOConnectionInfo</code> instance which tells KeePassLib where to find the database on the local file system.</td></tr>
<tr><td width="30%">2. Keys</td><td>The <code>Keys</code> property contains the collection of keys required to open the database. In this case, for testing, it is only the one <code>KeePassLib.Keys.KcpPassword</code> key 12345 which is required.</td></tr>
<tr><td width="30%">3. LiteralPath</td><td>This is a string with the literal path of the database file on disk.</td></tr>
<tr><td width="30%">4. Secrets</td><td>This is the <code>KeePassLib.PwDatabase</code> instance from which you can access all the entries in the test database starting with the <code>RootGroup</code> property.</td></tr>
<tr><td width="30%">5. StatusLogger</td><td>The custom <code>PowerPass.StatusLogger</code> instance which KeePassLib writes to as it operates on the database file.</td></tr>
</table>

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [How It Works](https://chopinrlz.github.io/powerpass/readme-cont) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)