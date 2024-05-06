# Roadmap
Here is the roadmap of upcoming features.
## TPM Support on Linux
Currently under development is TPM support for Linux.
| As of January 26, 2024 | Status |
| --- | --- |
| Initalize Context | Complete |
| Get Info | Complete |
| Create Key | Pending |
| Encrypt Locker | Pending |
| Decrypt Locker | Pending |
| Unit Testing | Available |

The library chosen to provide support is the open-source **[tpm2-tss](https://github.com/tpm2-software/tpm2-tss)** project.
A TPM is a Trusted Platform Module which is a device that stores private keys which cannot be exported from the system by any user.
The TPM device can be used to encrypt data without exposing the private keys to either admins or users.
As such, an attacker with root privileges would have no means of acquiring the key to decrypt the data leaving brute-force as the only option.
Check the [/tpm](https://github.com/chopinrlz/powerpass/tree/main/tpm) folder in this repo for ongoing updates.
### Can I use PowerPass TPM Edition?
If you are using Linux, the answer is (almost certainly) Yes.
You will first need to compile the **[tpm2-tss](https://github.com/tpm2-software/tpm2-tss)** source and deploy the binaries for your Linux distro.
The **tpm2-tss** project has an install guide [here](https://github.com/tpm2-software/tpm2-tss/blob/master/INSTALL.md).
This project supports all major Linux distros including Debian, Fedora, and Ubuntu.

Once you have **tpm2-tss** deployed you can test for TPM support by running `Test-TpmProvider.ps1` from the `/tpm` directory in this repo.
This PowerShell script will compile the `powerpasstpm` binary using `gcc` via the included `makefile` then run it in test mode and fetch the TPM info from the **tpm2-tss** Feature API.
### Compiling
The PowerPass TPM edition module is called `powerpasstpm`.
The module is written in `C` and is compiled using the GNU Compiler Collection or `gcc`.

1. To compile `powerpasstpm` simply run `make`
2. To clean up and recompile `powerpasstpm` run `make clean` then `make` again

The `makefile` in the `/tpm` directory assumes your **tpm2-tss** libraries are in `/usr/local/lib`.
If they are elsewhere, you will have to edit the `makefile` for now at least until I make it dynamic.
### Testing
You can test `powerpasstpm` with the included `Test-TpmProvider.ps1` PowerShell script or you can just run `powerpasstpm` from the shell.
| Test commands |||
| -- | -- | -- |
| ./powerpasstpm test | Runs in test mode | Outputs TPM info in JSON format to the console |
| ./powerpasstpm test > info.json | Runs in test mode | Saves TPM info to JSON file for review |

The `test` action for `powerpasstpm` invokes the `Fapi_GetInfo` function of the [TCG TPM2 Feature API](https://trustedcomputinggroup.org/resource/tss-fapi/) which echoes all the TPM capabilities of your system in JSON format.