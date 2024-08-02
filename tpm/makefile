# makefile for building powerpasstpm
# Copyright 2023-2024 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.

# Instructions for Usage
# If you are starting from scratch and you do not have tpm2-tss installed already,
# follow these steps.
#   1) Run 'sudo make depends' to install the prerequisite packages
#   2) Run 'make tpm2-tss-release' to build tpm2-tss from the latest Github release or 'make tpm2-tools' to build tpm2-tss from the master source on Github
#   3) Once that is done, cd to the tpm2-tss subdirectory and run 'sudo make install' to deploy tpm2-tss
#   4) Back in /powerpass/tpm run 'sudo make post' to run the tpm2-tss post-installation steps
#   5) Run 'make perms' to add your account to the new tss group (do NOT run sudo make perms)
#   6) The previous step changes your membership so you'll need to logoff and log in again
#   7) Run 'make' to build powerpasstpm with gcc
#   8) Now you can deploy PowerPass using the built-in script
# If you also want to install tpm2-tools, follow these steps:
#   1) Run 'sudo make depends' to install the prerequisite packages
#   2) Run 'make tpm2-tools' to build tpm2-tools from the master source on Github
#   3) Once that is done, cd to the tpm2-tools subdirectory and run 'sudo make install' to deploy tpm2-tools
# Optional recipes:
#  make clean (will remove all downloaded items and all compiled binaries)
#  sudo make depends (will install all dependencies for tpm2-tss, tpm2-tools and powerpasstpm)

SHELL=/bin/bash

USR_LIB != echo /usr/lib
NPROC != nproc
TPM2_TSS_DIR != if [ -d "./tpm2-tss" ]; then echo 1; fi
TPM2_TOOLS_DIR != if [ -d "./tpm2-tools" ]; then echo 1; fi
WHOAMI != echo $$(whoami)

# Recipe: powerpasstpm
# Compiles the powerpasstpm C code and links it to tpm2-tss libraries
# Outputs the powerpasstpm binary

powerpasstpm:
	gcc -c powerpasstpm.c -o powerpasstpm.o
	gcc powerpasstpm.o -L/usr/local/lib -ltss2-fapi -ltss2-rc -o powerpasstpm

# Recipe: tpm2-tss-release
# Downloads, configures and compiles the tpm2-tss library from Github
# Release version 4.1.3
# https://github.com/tpm2-software/tpm2-tss
# The output of this can be installed using sudo make install

tpm2-tss-release:
ifdef TPM2_TSS_DIR
	rm -rf ./tpm2-tss
	curl -L -o tpm2-tss.tar.gz https://github.com/tpm2-software/tpm2-tss/releases/download/4.1.3/tpm2-tss-4.1.3.tar.gz
	tar xzf tpm2-tss.tar.gz
endif
ifndef TPM2_TSS_DIR
	curl -L -o tpm2-tss.tar.gz https://github.com/tpm2-software/tpm2-tss/releases/download/4.1.3/tpm2-tss-4.1.3.tar.gz
	tar xzf tpm2-tss.tar.gz
endif
	mv tpm2-tss-4.1.3 tpm2-tss
	cd ./tpm2-tss; ./bootstrap; ./configure --with-udevrulesdir=/etc/udev/rules.d --with-udevrulesprefix=80; make -j$(NPROC)
	@echo Next steps: cd to ./tpm2-tss and run sudo make install to install TPM2-TSS

# Recipe: tpm2-tss
# Downloads, configures and compiles the latest DEV snapshot of the tpm2-tss library from Github
# https://github.com/tpm2-software/tpm2-tss
# The output of this can be installed using sudo make install

tpm2-tss:
ifdef TPM2_TSS_DIR
	rm -rf ./tpm2-tss
	git clone https://github.com/tpm2-software/tpm2-tss.git
endif
ifndef TPM2_TSS_DIR
	git clone https://github.com/tpm2-software/tpm2-tss.git
endif
	cd ./tpm2-tss; ./bootstrap; ./configure --with-udevrulesdir=/etc/udev/rules.d --with-udevrulesprefix=80; make -j$(NPROC)
	@echo Next steps: cd to ./tpm2-tss and run sudo make install to install TPM2-TSS

# Recipe: post
# Executes the required commands after deploying tpm2-tss
# Reloads udev rules, updates shared library cache

post:
	@echo Reloading udev rules
	sudo udevadm control --reload-rules && sudo udevadm trigger
	@echo Updating shared library cache
	sudo ldconfig

# Recipe: perms
# Adds the current user to the new tss group so it can write to the profiles directory
# When tpm2-tss is deployed, the TPM profiles directory is writable by the tss group
# If you are not added to the tss group, you cannot create TPM profiles and the Feature
# API cannot function correctly.

perms:
	@echo Adding $(WHOAMI) to the tss group
	sudo usermod -a -G tss $(WHOAMI)
	@echo Next steps: you must log out and log back in for your new permissions to take effect

# Recipe: tpm2-tools
# Downloads, configures and compiles the tpm2-tools binaries from Github
# https://github.com/tpm2-software/tpm2-tools
# The output of this can be installed using sudo make install

tpm2-tools:
ifdef TPM2_TOOLS_DIR
	tm -rf ./tpm2-tools
	git clone https://github.com/tpm2-software/tpm2-tools.git
endif
ifndef TPM2_TOOLS_DIR
	git clone https://github.com/tpm2-software/tpm2-tools.git
endif
	cd ./tpm2-tools; ./bootstrap; ./configure; make -j$(NPROC)
	@echo Next steps: cd to ./tpm2-tools and run sudo make install to install TPM2-TOOLS

# Recipe: depends
# Instructs the operating system to install all the required libraries for all
# the tools compiled by this makefile

depends:
	sudo apt -y install autoconf-archive libcmocka0 libcmocka-dev procps iproute2 build-essential git pkg-config gcc libtool automake libssl-dev uthash-dev autoconf doxygen libjson-c-dev libini-config-dev libcurl4-openssl-dev uuid-dev libltdl-dev libusb-1.0-0-dev libftdi-dev

# Recipe: clean
# Removes everything that has been downloaded or compiled

clean:
	@rm -f tpm2-tss.tar.gz
	@rm -f powerpasstpm.o
	@rm -f powerpasstpm
	@rm -rf ./tpm2-tss
	@rm -rf ./tpm2-tools