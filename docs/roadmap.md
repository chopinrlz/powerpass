# Roadmap
#### _Revised: October 8, 2025_
Here is the roadmap of upcoming features.

## Security Hardening
Currently under development is security hardening for the Locker contents while resident in memory.
The purpose of this update is to protect against malware attempting to read the memory contents of the PowerShell process.
In general this is not a concern because operating systems typically prevent processes from arbitrarily attaching to other processes and reading their memory.
But, let's say you accidentally click "Allow" when the UAC popup appears and the process finds your PowerShell window.
How can we protect ourselves from this situation?
The Locker implementation is being hardened to ensure that Locker secrets in-memory are scrambled.
Planned changes include:
<table>
<tr><th>Update</th><th>Purpose</th></tr>
<tr><td>Port Locker to C#</td><td>Move the Locker object into C# to allow for implementations across the AES and DP API editions of PowerPass and to more readily support the <code>IDisposable</code> interface and <code>byte[]</code> data structures to ensure sensitive memory areas are cleared when the Locker is closed</td></tr>
<tr><td>Generate a Memory Key</td><td>Build a new non-memory-resident ephemeral key to use as a one-time-pad for encrypted retention of the Locker while in memory</td></tr>
<tr><td>Encrypt In-Memory Secret Values</td><td>Use the ephemeral one-time-pad value to encrypt and decrypt the values of the Locker secrets in-memory after reading them from disk when they are requested by the user</td></tr>
</table>

### `String` vs `SecureString`
As always, the main limitation of this security hardening is PowerShell itself which works primarily with strings.
Strings are immutable data types that cannot be "erased" when they are done being used.
PowerPass will continue to give you the option to fetch your Locker secrets as `String` types because they are the most flexible for you.
These Strings will remain resident in memory, unencrypted, for as long as the PowerShell window remains open.
You will always have the option to use a `SecureString` to harden your own implementations which is the default Password data type for Locker secrets.

### Is PowerPass Still Secure Now?
Yes, your Locker secrets and Locker key/salt are encrypted while resident on disk.
The purpose of this security hardening is to make it difficult for __other programs also running on your computer__ to read your Locker secrets __from memory__ in the event that your computer becomes infected with malware.

## Web Browser PowerPass
Currently under development is a port of PowerPass into TypeScript for use with a web browser as a fully client-side password manager that can be hosted anywhere and uses local storage for your Locker.
<table>
<tr><th>As of January 30, 2025</th><th>Status</th></tr>
<tr><td>Core Functions</td><td>In Progress</td></tr>
<tr><td>Serialization</td><td>Not Started</td></tr>
<tr><td>Key Generation</td><td>Not Started</td></tr>
<tr><td>Encryption</td><td>Not Started</td></tr>
<tr><td>Descryption</td><td>Not Started</td></tr>
<tr><td>User Interface</td><td>Not Started</td></tr>
<tr><td>Unit Testing</td><td>Not Started</td></tr>
</table>

### Encryption for the Web Browser Edition
The browser edition of PowerPass will use the same 256-bit AES encryption as the PowerShell editions.
A cryptography API has yet to be chosen, but it will likely be the [Web Crypto API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Crypto_API) or [CryptoJS](https://github.com/brix/crypto-js) which has since been discontinued, so it is likely the native Web Crypto API will be used.

## TPM Support on Linux
Currently under development is TPM support for Linux.
<table>
<tr><th>As of January 30, 2025</th><th>Status</th></tr>
<tr><td>Initialize Context</td><td>Complete</td></tr>
<tr><td>Get Info</td><td>Complete</td></tr>
<tr><td>Create Key</td><td>Complete</td></tr>
<tr><td>Encrypt Locker</td><td>Proofed</td></tr>
<tr><td>Decrypt Locker</td><td>Pending</td></tr>
<tr><td>Unit Testing</td><td>Available</td></tr>
<tr><td>Installation</td><td>In Progress</td></tr>
</table>

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

### Installing tpm2-tss via PowerPass
The PowerPass repo includes `make` recipes for `tpm2-tss` on Ubuntu which have been tested on Ubuntu 22 and Ubuntu 24.
These recipes require `git` and will pull down `tpm2-tss` from Git and run the required shell commands to build `tpm2-tss`.
If you are using Ubuntu, you can install `tpm2-tss` using `make` from the `powerpass/tpm` directory using the following shell commands:
#### 1. sudo make depends
```bash
user@server:~/powerpass/tpm$ sudo make depends
```
From the `tpm` directory of the PowerPass repo, run `sudo make depends`. Running `sudo make depends` will install all dependencies for both `tpm2-tss` and `tpm2-tools` to your environment.
#### 2. make tpm2-tss
```bash
user@server:~/powerpass/tpm$ make tpm2-tss
```
Also from the `tpm` directory of the PowerPass repo, run `make tpm2-tss`. Running `make tpm2-tss` will use Git to clone the latest `tpm2-tss` version into the current directory, bootstrap, configure, and compile the libraries.
#### 3. sudo make install
```bash
user@server:~/powerpass/tpm/tpm2-tss$ sudo make install
```
Next, you need to run `sudo make install` from the `tpm2-tss` subdirectory to install `tpm2-tss` to your environment.
#### 4. sudo make post
```bash
user@server:~/powerpass/tpm$ sudo make post
```
Now, back in the `tpm` subdirectory of the PowerPass repo, run `sudo make post` which will reload your udev rules and run ldconfig per the instructions from the `tpm2-tss` INSTALL file.
The Feature API will not work if you do not perform this step.
#### 5. sudo usermod -a -G tss user
```bash
user@server:~/powerpass/tpm$ sudo usermod -a -G tss [user]
```
Finally, you need to add your user account to the `tss` group.
This allows your user account to write into the profiles directory created by `tpm2-tss` during `sudo make install`.
For this to take effect, you will need to log off and log back in again before you proceed.

### Compiling
Once you have `tpm2-tss` fully setup and ready to go, you can compile the PowerPass TPM module.
The PowerPass TPM edition module is called `powerpasstpm`.
The module is written in `C` and is compiled using the GNU Compiler Collection or `gcc`.

1. To compile `powerpasstpm` simply run `make` from the `/powerpass/tpm` directory
2. To clean up and recompile `powerpasstpm` run `make clean` then `make` again

NOTE: The `makefile` in the `/tpm` directory assumes your **tpm2-tss** libraries are in `/usr/local/lib`.
If they are elsewhere, you will have to edit the `makefile` for now at least until I make it dynamic.

### Testing Your TPM
Now that everything is setup, you can test for TPM support by running `Test-TpmProvider.ps1` from the `/tpm` directory in this repo.
This PowerShell script will compile the `powerpasstpm` binary using `gcc` via the included `makefile` if you have not already done so.
It will run `./powerpasstpm` in test mode and fetch the TPM info from the **tpm2-tss** Feature API.
Lastly, it will echo the object properties received from the TPM using `Get-Member`.
The `tpm2-tss` library returns JSON for the TPM info.
You can take the output of `./powerpasstpm test` and pipe it to `ConvertFrom-Json` to get an object and inspect it with PowerShell.

### Testing
You can test `powerpasstpm` with the included `Test-TpmProvider.ps1` PowerShell script or you can just run `powerpasstpm` from the shell.
<table>
<tr><th>Test commands</th><th></th><th></th></tr>
<tr><td>./powerpasstpm test</td><td>Runs in test mode</td><td>Outputs TPM info in JSON format to the console</td></tr>
<tr><td>./powerpasstpm test > info.json</td><td>Runs in test mode</td><td>Saves TPM info to JSON file for review</td></tr>
</table>

The `test` action for `powerpasstpm` invokes the `Fapi_GetInfo` function of the [TCG TPM2 Feature API](https://trustedcomputinggroup.org/resource/tss-fapi/) which echoes all the TPM capabilities of your system in JSON format.

### Initialization
You can initialize PowerPass TPM edition by running:
```bash
$ ./powerpasstpm init
```
When you run the `init` command, the PowerPass TPM module will attempt to provision the Feature API for the TSS2 TPM library and create an encryption key in the TPM for the PowerPass Locker.
This will be handled automatically for you in the future from the deploy script, but for now you can run this from the shell.

### Encrypting
You can test encryption using the PowerPass Locker key by running:
```bash
$ ./powerpasstpm enc
```
When you run the `enc` command, the PowerPass TPM module will attempt to encrypt a block of random data using the Locker key created during the `init` routine.
If successful, you will see the plain-text data and the encrypted data echoed to the terminal.

# All PowerPass Topics
Select one of the links below to browse to another topic.
## [AES Cmdlet Reference](https://chopinrlz.github.io/powerpass/aes-cmdlet-ref) | [Data Structures](https://chopinrlz.github.io/powerpass/data-structures) | [Deployment](https://chopinrlz.github.io/powerpass/deployment) | [Domain Credentials](https://chopinrlz.github.io/powerpass/domain-credentials) | [DP API Cmdlet Reference](https://chopinrlz.github.io/powerpass/dpapi-cmdlet-ref) | [Home](https://chopinrlz.github.io/powerpass) | [How It Works](https://chopinrlz.github.io/powerpass/readme-cont) | [OneDrive Backup](https://chopinrlz.github.io/powerpass/onedrivebackup) | [Prerequisites](https://chopinrlz.github.io/powerpass/prerequisites) | [Release Notes](https://chopinrlz.github.io/powerpass/release-notes) | [Roadmap](https://chopinrlz.github.io/powerpass/roadmap) | [Usage](https://chopinrlz.github.io/powerpass/usage)