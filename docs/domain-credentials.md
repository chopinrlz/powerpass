# Storing and Retrieving Domain Credentials with PowerPass
#### _Revised: January 11, 2024_
# Introduction
PowerPass can be used to store and retrieve domain credentials from your Locker or from a KeePass 2 database.
Many Windows PowerShell modules require the use of the `PSCredential` object to connect to resources protected by a domain account.
PowerPass can automatically convert secrets from your Locker into `PSCredential` objects.
Secrets from KeePass 2 databases, however, cannot be automatically converted at this time, but can be easily converted with a few lines of PowerShell.
This article which explain how to store and retrieve domain credentials using PowerPass.
# Locker Secrets
When storing an Active Directory domain credential in your PowerPass Locker, follow these simple conventions to ensure that you can successfully retrieve a `PSCredential` automatically using the `Read-PowerPassSecret` cmdlet.
## Domain Name and Login Name
When calling `Write-PowerPassSecret` append the NetBIOS Domain Name to the Login name with a `\` separator, like so:
```powershell
Write-PowerPassSecret -Title "Domain Credential" -UserName "DOMAIN\logonName"
```
You can also use the DNS name of the domain, rather than the NetBIOS name, by appending the domain name to the login name with an `@` separator as if it were an email address, like so:
```powershell
Write-PowerPassSecret -Title "Domain Credential" -UserName "logonName@domain.local"
```
## Password
The `Password` for the domain credential secret can be set by any means, either by using the `-Password` parameter or by using the `-MaskPassword` parameter.
Active Directory generally does not allow logon using a domain credential without a password.
# KeePass 2 Databases
KeePass 2 databases are user-defined, meaning that when you store secret in KeePass 2, you can choose how to store the Domain Name and Login Name in KeePass 2.
As such, there is no standardized way to store domain credentials in KeePass 2.
Regardless, when you fetch a secret from a KeePass 2 database, you can easily convert it to a `PSCredential` using the following PowerShell:
```powershell
# Open the KeePass 2 database with my Windows logon as the key
$database = Open-PowerPassDatabase -Path "C:\Secrets\MyDatabase.kdbx" -WindowsUserAccount
$secret = Get-PowerPassSecret -Database $database -Match "Domain Credential"
$psCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList @(($secret.UserName), ($secret.Password))
```
The assumption here is that the `UserName` field from your KeePass 2 database contains the Domain Name and Logon Name in one of these two formats:
1. DOMAIN\logonName
2. logonName@domain.local

The first option uses the NetBIOS domain name while the second option uses the DNS domain name.
# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Usage](https://chopinrlz.github.io/powerpass/usage)