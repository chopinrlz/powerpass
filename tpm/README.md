# PowerPass for Linux with TPM Encryption
## __September 22, 2024__
# Introduction
Welcome to the README for the TPM edition of PowerPass.
This edition of PowerPass uses the device's TPM or Trusted Platform Module to your PowerPass Locker.
These instructions were written for Ubuntu 24.04.
If you are using a different operating system you will need to adapt them to your environment, but the concepts are the same: PowerPass TPM edition depends on [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) which is supported on Debian, Ubuntu and Fedora.
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
## 3. Install tpm2-tss
Running make for the tpm2-tss-release recipe will create a new subdirectory called `tpm2-tss`.
Go ahead and `cd tpm2-tss` to switch into that directory.
Assuming everything went well during the previous step, `tpm2-tss` will be ready to install with:
### `sudo make install`
Make sure you run that from the `tpm2-tss` subdirectory of you'll get an error.
This will install [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) onto your system.
## 4. Execute the Post-Installation Steps
Now that you have [tpm2-tss](https://github.com/tpm2-software/tpm2-tss) installed you will need to run the post-installation steps before it will work properly.
Switch directories back to the parent directory underneath `tpm2-tss` where you started this and run:
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
## 8. Deploy PowerPass
Finally, with the `powerpasstpm` binary built, you can deploy PowerPass TPM edition using the built-in `Deploy-PowerPass.ps1` PowerShell script included with the repo at the root.