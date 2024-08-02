# makefile for building powerpasstpm
# Copyright 2023-2024 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
SHELL=/bin/bash

USR_LIB != echo /usr/lib
NPROC != nproc
TPM2_TSS_DIR != if [ -d "./tpm2-tss" ]; then echo 1; fi
TPM2_TOOLS_DIR != if [ -d "./tpm2-tools" ]; then echo 1; fi
WHOAMI != echo whoami

# If you are starting from scratch and you do not have tpm2-tss installed already,
# follow these steps.
#   1) Run 'sudo make depends' to install the prerequisite packages
#   2) Run 'make tpm2-tss-release' to build tpm2-tss from the latest Github release or 'make tpm2-tools' to build tpm2-tss from the master source on Github
#   3) Once that is done, cd to the tpm2-tss subdirectory and run 'sudo make install' to deploy tpm2-tss
#   4) Back in /powerpass/tpm run 'sudo make post' to run the tpm2-tss post-installation steps
#   5) The previous step adds your user account to the new tss group so you'll need to logoff and log in again
#   6) Run 'make' to build powerpasstpm with gcc
#   7) Now you can deploy PowerPass using the built-in script
# If you also want to install tpm2-tools, follow these steps:
#   1) Run 'sudo make depends' to install the prerequisite packages
#   2) Run 'make tpm2-tools' to build tpm2-tools from the master source on Github
#   3) Once that is done, cd to the tpm2-tools subdirectory and run 'sudo make install' to deploy tpm2-tools
# Optional recipes:
#  make clean (will remove all downloaded items and all compiled binaries)
#  sudo make depends (will install all dependencies for tpm2-tss, tpm2-tools and powerpasstpm)

powerpasstpm:
	gcc -c powerpasstpm.c -o powerpasstpm.o
	gcc powerpasstpm.o -L/usr/local/lib -ltss2-fapi -ltss2-rc -o powerpasstpm
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
	@echo Run sudo make install to install TPM2-TSS
tpm2-tss:
ifdef TPM2_TSS_DIR
	rm -rf ./tpm2-tss
	git clone https://github.com/tpm2-software/tpm2-tss.git
endif
ifndef TPM2_TSS_DIR
	git clone https://github.com/tpm2-software/tpm2-tss.git
endif
	cd ./tpm2-tss; ./bootstrap; ./configure --with-udevrulesdir=/etc/udev/rules.d --with-udevrulesprefix=80; make -j$(NPROC)
	@echo Run sudo make install to install TPM2-TSS
post:
	@echo Reloading udev rules
	sudo udevadm control --reload-rules && sudo udevadm trigger
	@echo Updating shared library cache
	sudo ldconfig
	@echo Adding $(WHOAMI) to the tss group
	sudo usermod -a -G tss $(WHOAMI)
	@echo You must log out and log back in for your new permissions to take effect
tpm2-tools:
ifdef TPM2_TOOLS_DIR
	tm -rf ./tpm2-tools
	git clone https://github.com/tpm2-software/tpm2-tools.git
endif
ifndef TPM2_TOOLS_DIR
	git clone https://github.com/tpm2-software/tpm2-tools.git
endif
	cd ./tpm2-tools; ./bootstrap; ./configure; make -j$(NPROC)
	@echo Run sudo make install to install TPM2-TOOLS
depends:
	sudo apt -y install autoconf-archive
	sudo apt -y install libcmocka0
	sudo apt -y install libcmocka-dev
	sudo apt -y install procps
	sudo apt -y install iproute2
	sudo apt -y install build-essential
	sudo apt -y install git
	sudo apt -y install pkg-config
	sudo apt -y install gcc
	sudo apt -y install libtool
	sudo apt -y install automake
	sudo apt -y install libssl-dev
	sudo apt -y install uthash-dev
	sudo apt -y install autoconf
	sudo apt -y install doxygen
	sudo apt -y install libjson-c-dev
	sudo apt -y install libini-config-dev
	sudo apt -y install libcurl4-openssl-dev
	sudo apt -y install uuid-dev
	sudo apt -y install libltdl-dev
	sudo apt -y install libusb-1.0-0-dev
	sudo apt -y install libftdi-dev
clean:
	@rm -f powerpasstpm.o
	@rm -f powerpasstpm
	@rm -rf ./tpm2-tss
	@rm -rf ./tpm2-tools