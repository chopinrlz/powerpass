# makefile for building powerpasstpm
# Copyright 2023-2024 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
SHELL=/bin/bash

USR_LIB != echo /usr/lib
NPROC != nproc
TPM2_TSS_DIR != if [ -d ~/tpm2-tss ]; then echo 1; fi

# Instructions:
#  make
# Optional:
#  make tpm2-tss
#  sudo make post
#  make clean
#  sudo make depends
# tpm2-tss must be deployed as root

powerpasstpm:
	gcc -c powerpasstpm.c -o powerpasstpm.o
	gcc powerpasstpm.o -L/usr/local/lib -ltss2-fapi -ltss2-rc -o powerpasstpm
tpm2-tss:
ifdef TPM2_TSS_DIR
	rm -rf ~/tpm2-tss
	cd ~
	git clone https://github.com/tpm2-software/tpm2-tss.git
endif
ifndef TPM2_TSS_DIR
	cd ~
	git clone https://github.com/tpm2-software/tpm2-tss.git
endif
	cd ~/tpm2-tss
	./bootstrap
	./configure --with-udevrulesdir=/etc/udev/rules.d --with-udevrulesprefix=80
	make -j$(nproc)
	cd ~/tpm2-tss
	echo Run sudo make install to install TPM2-TSS
post:
	sudo udevadm control --reload-rules && sudo udevadm trigger
	sudo ldconfig
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
	@rm -rf tpm2-tss-4.0.1
	@rm -f tpm2-tss-4.0.1.tar.gz