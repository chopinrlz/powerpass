# makefile for building powerpasstpm
# Copyright 2023-2024 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
SHELL=/bin/bash

USR_LIB != echo /usr/lib
NPROC != nproc
TPM2_TSS_DIR != if [ -d "./tpm2-tss-4.0.1" ]; then echo 1; fi

# Instructions:
#  make
# Optional:
#  sudo make tpm2-tss
#  make clean
# tpm2-tss must be deployed as root

powerpasstpm:
	gcc -c powerpasstpm.c -o powerpasstpm.o
	gcc powerpasstpm.o -L/usr/local/lib -ltss2-fapi -ltss2-rc -o powerpasstpm
tpm2-tss:
ifndef TPM2_TSS_DIR
	curl -LO https://github.com/tpm2-software/tpm2-tss/releases/download/4.0.1/tpm2-tss-4.0.1.tar.gz
	tar -xv -f tpm2-tss-4.0.1.tar.gz
	cd ./tpm2-tss-4.0.1/; ./configure --prefix=$(USR_LIB); make -j$(NPROC); make install
endif
clean:
	@rm -f powerpasstpm.o
	@rm -f powerpasstpm
	@rm -rf tpm2-tss-4.0.1
	@rm -f tpm2-tss-4.0.1.tar.gz