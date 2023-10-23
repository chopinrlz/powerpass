# PowerPass
A PowerShell module for secret storage and retrieval based on the KeePass 2.55 implementation. This module will allow you to fetch secrets from any KeePass database compatible with KeePass 2.55. This module is currently only compatible with Windows since KeePassLib is compiled on the .NET Framework.
# Deployment
PowerPass comes with a deployment script which will compile the KeePassLib and deploy the module. Clone this repository to a writeable folder on your local machine. Open Windows PowerShell 5.1 and run ```.\Deploy-Module.ps1``` to compile and deploy this module.
## Prerequisites
You will need:
1. PowerShell 5.1
2. .NET Framework 4.7.2
3. C# Compiler (typically included with 2.)
# KeePassLib
PowerPass comes bundled with the KeePassLib 2.55 source code which is copyright 2003-2023 Dominik Reichl <dominik.reichl@t-online.de> and is licensed under the GNU Public License 2.0. A copy of this license is included in the LICENSE file in this repository. KeePassLib has not been modified from its release version. You can use PowerPass with KeePassLib 2.55 or with your own version of KeePassLib.
# Test Database Password
The master password to the test database TestDatabase.kdbx is "12345" without the quotation marks.