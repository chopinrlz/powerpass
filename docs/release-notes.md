The latest release of PowerPass version 1.5.0 adds support for masked password entry, locker searching by Title (not just match), pipeline optimization, includes more test coverage, and fixes a read bug when accessing an empty locker.
# New Features and Optimization
## Masked Password Entry
Up until now, the `Write-PowerPassSecret` cmdlet relied on the `-Password` parameter to set passwords for secrets in your locker. As such, passwords had to be shown on the console if typed them in. Now, a new parameter `-MaskPassword` gives you the option to be prompted to enter a password which is masked as you type. For more information please refer to the cmdlet reference for [AES cmdlets](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref#write-powerpasssecret) and/or the [DP API cmdlets](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref#write-powerpasssecret).
## Title Parameter for Read-PowerPassLocker
Up until now, the `Read-PowerPassSecret` cmdlet would only let you specify a `-Match` parameter despite the fact that the searching was done against the `Title` property of the secrets collection. For consistency and intuitiveness, a new exact-match `-Title` parameter has been added to the `Read-PowerPassSecret` cmdlet given that it makes the use of the cmdlet more intuitive. For more information please refer to the cmdlet reference for [AES cmdlets](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref#read-powerpasssecret) and/or the [DP API cmdlets](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref#read-powerpasssecret).
## Pipeline Optimization
The `Write-PowerPassSecret` cmdlet has been optimized for pipeline input. You can now pipeline secrets in bulk into the write cmdlet which will optimize the loading of secrets rather than invoking the cmdlet once for each secret in a large collection. The parameters for secrets can also be pipelined by name making things like this:
```powershell
Import-Csv "secrets.csv" | Write-PowerPassSecret
```
as easy as a single line of PowerShell. This example also executes significantly faster than if one were to use a loop.
## Additional Test Coverage
The unit testing scripts have been updated to cover more scenarios. Unit testing failed to catch several minor bugs and was also not configrued to verify optimizations. The unit tests have been updated to run a more comprehensive battery of tests and also to measure write performance.
# Bug Fixes
## Issue # 3: [Read throws an error if your locker is empty](https://github.com/chopinrlz/powerpass/issues/3)
`Read-PowerPassSecret` no longer throws an error if you invoke it with an empty locker.
# Deployment
The deployment script has been modified and is now much quieter than before. To install PowerPass:
1. Clone the repo, download the release, or download the source code for this release
2. Run `.\Deploy-PowerPass.ps1` in any PowerShell terminal (you will need write access to this folder)
# File Hashes
| Release                 | SHA256 Hash                                                      |
| ----------------------- | ---------------------------------------------------------------- |
| PowerPass-1.5.0.tar.gz  | tbd |
| PowerPass-1.5.0.zip     | tbd |