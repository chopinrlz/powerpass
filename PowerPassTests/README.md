# PowerPass Tests
## Running Tests
To run the tests against the PowerPass module, run the ```.\Test-PowerPass.ps1``` script from any Windows PowerShell terminal.
## Manifest
### keepass-keyfile.keyx
This is the key file for the KeePass test databases.
### kpdb-key.kdbx
This is a KeePass database locked with a key file.
### kpdb-keypw.kdbx
This is a KeePass database locked with a key and master password.
### kpdb-pw.kdbx
This is a KeePass database locked with a master password.
### kpdb-pwmulti.kdbx
This is a KeePass database locked with a master password with multiple identical and unique entries.
### Test-PowerPass.ps1
This is the test script for PowerPass that runs all test cases. It will write ```Assert passed``` to the host window for each passed test case.
### test-pw.txt
This is the master password for the KeePass test databases.