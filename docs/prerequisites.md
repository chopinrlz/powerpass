# Prerequisites
## AES
If you deploy the AES implementation of PowerPass on Windows PowerShell, or are using PowerShell 7, there are no prerequisites.
PowerPass AES will work natively with Windows PowerShell or PowerShell 7.
## Data Protection API
If you deploy the Data Protection API implementation of PowerPass on Windows PowerShell, you must have the .NET Framework installed (which you likely already will) as well as the C# compiler if you compile KeePassLib from source.
### .NET Framework 4.8.1
PowerPass is designed to work with the latest version of the .NET Framework 4.8.1.
### C# Compiler
PowerPass is compiled from source at deployment time.
You must have the C# compiler installed with the .NET Framework.
It is typically included by default.
Newer releases of PowerPass include a compiled KeePassLib.dll assembly which you can use if you do not want to compile from source.