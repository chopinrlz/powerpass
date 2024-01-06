# PowerPass Unit Tests
Welcome to the PowerPass Unit Tests directory.
The scripts and files in this directory will let you test the functionality of PowerPass.
Certain tests cannot be automated, such as opening a KeePass 2 database with your User profile key.
This can only be done by yourself under your own profile.
For all other possible test cases, these have been scripted here to verify PowerPass.
# Release Testing
Before a release of PowerPass is published, the releaes is tested using these scripts.
Here are the following tests which are executed:
| Script | Test Host |
| - | - |
| 1. `Test-AesCrypto.ps1` | PowerShell 7 |
| | Windows PowerShell 5.1 |
| 2. `Test-ModuleAes.ps1` | PowerShell 7 |
| | Windows PowerShell 5.1 |
| 3. `Test-ModuleDpApi.ps1` | Windows PowerShell 5.1 |
# Testing Setup
Running these tests requires you to erase your PowerPass Locker.
If you do this in a Production or Staging environment you should export your PowerPass Locker prior to running these tests.
To setup for testing, perform a clean install of PowerPass by running `Deploy-PowerPass.ps1` from the root of this repo.
When running the deploy script, you must select to install the version of PowerPass that you intend to test, either the AES or DPAPI version.
# Unit Tests
## Test-AesCrypto.ps1
These unit tests verify the functionality of the `AesCrypto.cs` class which wraps the AES crypto implementation of .NET into a helper class providing a simple API for PowerPass to consume for AES support on PowerShell 7 or Windows PowerShell 5.1.
## Test-ModuleAes.ps1
These unit tests verify the functionality of the AES edition of PowerPass which can run on either PowerShell 7 or Windows PowerShell 5.1. Be sure that you have the AES edition of PowerPass deployed before you run this unit test script.
## Test-ModuleDpApi.ps1
These unit tests verify the functionality of the Data Protection API (DPAPI) edition of PowerPass which can only run on Windows PowerShell 5.1.
These unit tests make use of the KeePass 2 databases contained in the `test` folder to verify functionality for KeePass 2 support.