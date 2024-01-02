# makefile for building and installing libpptpm
# Copyright 2023 by The Daltas Group LLC.
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
SHELL=/bin/bash

USR_LIB != echo /usr/lib
LIB_DIR != echo ~/lib
NPROC != nproc
TPM2_TSS_DIR != if [ -d "./tpm2-tss-4.0.1" ]; then echo 1; fi

# tpm2-tss must be deployed as root

install: library
	cp -f libpptpm.so $(LIB_DIR)
library: compile
	gcc -shared powerpasstpm.o -o libpptpm.so
compile:
	gcc -c -fPIC -l$(USR_LIB)/libtss2-fapi.so -static powerpasstpm.c -o powerpasstpm.o
tpm2-tss:
ifndef TPM2_TSS_DIR
	curl -LO https://github.com/tpm2-software/tpm2-tss/releases/download/4.0.1/tpm2-tss-4.0.1.tar.gz
	tar -xv -f tpm2-tss-4.0.1.tar.gz
	cd ./tpm2-tss-4.0.1/; ./configure --prefix=$(USR_LIB); make -j$(NPROC); make install
endif
clean:
	@rm -f powerpasstpm.o
	@rm -f libpptpm.so
	@rm -rf tpm2-tss-4.0.1
	@rm -f tpm2-tss-4.0.1.tar.gz