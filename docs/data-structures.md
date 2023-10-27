# Data Structures
## KeePass Database
When you run the `Open-PowerPassDatabase` cmdlet, the output is a `PSCustomObject` with these properties.
1. Connector
2. Keys
3. LiteralPath
4. Secrets
5. StatusLogger
### Property: Connector
The ```Connector``` property contains the ```KeePassLib.Serialization.IOConnectionInfo``` instance which tells KeePassLib where to find the database on the local file system.
### Property: Keys
The ```Keys``` property contains the collection of keys required to open the database. In this case, for testing, it is only the one ```KeePassLib.Keys.KcpPassword``` key 12345 which is required.
### Property: LiteralPath
This is a string with the literal path of the database file on disk.
### Property: Secrets
This is the ```KeePassLib.PwDatabase``` instance from which you can access all the entries in the test database starting with the ```RootGroup``` property.
### Property: StatusLogger
The custom ```PowerPass.StatusLogger``` instance which KeePassLib writes to as it operates on the database file.
## PowerPass Locker
The PowerPass Locker is not an exposed data type. However, for those who are curious, the Locker is a `PSCustomObject` with these properties. It is serialized as JSON before being encrypted and converted to a base-64 encoded string for storage.
1. Secrets
2. Attachments
3. Created
4. Edition
### Property: Secrets
The `Secrets` property is an array of `PSCustomObject` items with Title, UserName, Password, URL, Notes, Expires, Created, and Modified fields. When you call the `Read-PowerPassSecret` cmdlet one or more of these objects are output to the pipeline for you. The Password is stored as a `SecureString` unless you specify the `PlainTextPasswords` parameter.
### Property: Attachments
The `Attachments` property is an array of `PSCustomObject` items with FileName, Data, Created, and Modified fields. Data is output to you as a byte array, but is stored in the Locker as a base-64 encoded string.
### Property: Created
The `Created` property indicates when the Locker was created.
### Property: Edition
The `Edition` property is reserved for use by later editions of PowerPass to determine compatibility with future versions.