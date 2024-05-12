# Roadmap
Here is the roadmap of upcoming features.
## TPM Support on Linux
Currently under development is TPM support for Linux.
<table>
<tr><th>As of May 12, 2024</th><th>Status</th></tr>
<tr><td>Initalize Context</td><td>Complete</td></tr>
<tr><td>Get Info</td><td>Complete</td></tr>
<tr><td>Create Key</td><td>Complete</td></tr>
<tr><td>Encrypt Locker</td><td>Proofed</td></tr>
<tr><td>Decrypt Locker</td><td>Pending</td></tr>
<tr><td>Unit Testing</td><td>Available</td></tr>
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
You can take the output of `./powerpasstpm test` and pipe it to `ConvertFrom-Json` to get an object and inpect it with PowerShell.

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
If successful, you will see the plain-text data and the encrypted data echoed to the termainl.