# PowerPass for Linux with TPM Encryption
## __September 22, 2024__
# Introduction
Welcome to the README for the TPM edition of PowerPass.
This edition of PowerPass uses the device's TPM or Trusted Platform Module to encrypt your PowerPass Locker.
These instructions were written for Ubuntu 24.04.
If you are using a different operating system you will need to adapt them to your environment, but the concepts are the same: PowerPass TPM edition depends on [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) which is supported on Debian, Ubuntu and Fedora. PowerPass TPM is written in C and is compiled used gcc from `powerpasstpm.c` and `powerpasstpm.h`.
# Getting Started
If you are starting from scratch and you do not have [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) installed already, follow these steps to install both the prerequisites as well as the latest release [4.1.3](https://github.com/tpm2-software/tpm2-tss/releases/tag/4.1.3) of [tpm2-tss](https://github.com/tpm2-software/tpm2-tss).
## 1. Install Prerequisites
The makefile in this repo provides recipes for building and deploying tpm2-tss from a fresh installation of Linux.
Start by building the first recipe to install the prerequisite packages:
### `sudo make depends`
## 2. Build tpm2-tss from the 4.1.3 Release
The next recipe will pull down the 4.1.3 release of [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) for you and compile it from source.
The recipe makes some assumptions about where your `udev rules` are located and what `udev rules prefix` to use.
Check the `makefile` on line 58 if you need to make any changes.
### `make tpm2-tss-release`
You will need Internet access for this step (we're assuming you've had it all along) to download the release tarball from Github.
## 3. Install tpm2-tss
Running make for the tpm2-tss-release recipe will create a new subdirectory called `tpm2-tss`.
Go ahead and `cd tpm2-tss` to switch into that directory.
Assuming everything went well during the previous step, `tpm2-tss` will be ready to install with:
### `sudo make install`
Make sure you run that from the `tpm2-tss` subdirectory of you'll get an error.
This will install [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) onto your system.
## 4. Execute the Post-Installation Steps
Now that you have [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) installed you will need to run the post-installation steps before it will work properly.
Switch directories back to the parent directory underneath `tpm2-tss` where you started this with a quick `cd ..` and run:
### `sudo make post`
This will reload your `udev rules` and update the shared library cache.
## 5. Configure Permissions
The [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) stores encryption profiles in a non-user writable directory by default under `/etc`.
For your user account to provision the Feature API, which is used by PowerPass, your user account will need to be added to the `tss` group on the system.
Running:
### `make perms`
will add your account to the new `tss` group created by [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) during installation.
You will now need to log out and log back in for these permissions to take effect.
Do that now.
## 6. Log Out and Log Back In
Did you do that? Good. Let's keep going.
## 7. Build PowerPass TPM
One you get back into the directory where you started, run:
### `make`
to compile the PowerPass TPM binary `powerpasstpm` using `gcc`.
## 8. Test the PowerPass TPM Binary
Before you deploy PowerPass you should test the PowerPass TPM binary to make sure the [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) library deployed properly.
From the current directory, run:
### `./powerpasstpm test`
You should see two outputs echo to the terminal:
1. A very large JSON object from [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) with the crypto profiles for the TPM
2. A JSON object from PowerPass that says `{"powerpasstpm":"tpm","command":0,"result":0,"message":"success"}`

That last bit from PowerPass is the result code and message from running the PowerPass TPM `test` command.
If you do not see `success` or `"result":0` from `powerpasstpm` that means something went wrong and you'll need to debug the issue before you can proceed.
This step usually works fine, but the two most common errors are:
1. Permissions: your user account either isn't a member of `tss` or you didn't log out and log back in
2. You deployed [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) from a non-release build which has an issue with your current environment

[tpm2-tss](https://github.com/tpm2-software/tpm2-tss) version 4.1.3 has been tested thoroughly on Ubuntu 24.04.
The current master source does not always compile or work properly.
## 9. Initialize the PowerPass Encryption Key
To provision the Feature API and create an encryption key, run:
### `./powerpasstpm init`
This will provision the [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) Feature API and generate an encryption key for PowerPass to use to encrypt your Locker.
There are some known issues with this process:
### 9a. Unsupported URL scheme
You may see this error message in the output from [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) while running the `init` command for `powerpasstpm`.
This error is generated when the TPM for the current device uses a self-signed certificate, for example if you are running this on a virtual machine such as [VMware Workstation](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion) with a virtualized TPM.
To correct this, you'll need to tell [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) that it's OK to use a self-signed root certificate within the TPM.
You will need to open the `fapi-config.json` file in `vi` or `nano` and add the following property:
#### `"ek_cert_less": "yes"
to the JSON object in the file.
This will instruct the Feature API to avoid checking the self-signed certificate for the TPM.
The `fapi-config.json` file is typically located in `/usr/local/etc/tpm2-tss`,
## 10. Deploy PowerPass
Finally, with the `powerpasstpm` binary built and the encryption key initialized, you can deploy PowerPass TPM edition using the built-in `Deploy-PowerPass.ps1` PowerShell script included at the root of this repo.