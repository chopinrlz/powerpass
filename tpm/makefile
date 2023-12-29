# makefile for building and installing libpptpm
# Copyright 2023 by The Daltas Group LLC.
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
SHELL=/bin/bash

LIB_DIR := /usr/lib
NPROC != nproc
TPM2_TSS_URL := https://github.com/tpm2-software/tpm2-tss/releases/download/4.0.1/tpm2-tss-4.0.1.tar.gz
TPM2_TSS_TARBALL := tpm2-tss-4.0.1.tar.gz

libpptpm: powerpasstpm
	gcc -shared powerpasstpm.o -o libpptpm.so
powerpasstpm: tpm2-tss
	gcc -c -fPIC powerpasstpm.c -o powerpasstpm.o
tpm2-tss:
	curl -LO $(TPM2_TSS_URL)
	tar -xv -f $(TPM2_TSS_TARBALL)
	cd ./tpm2-tss-4.0.1/; ./configure --prefix=/usr; make -j$(NPROC)
tpm2-tss-install: tpm2-tss
	cd ./tpm2-tss-4.0.1/; make install
install: libpptpm
	cp -f libpptpm.so $(LIB_DIR)
clean:
	@rm -f powerpasstpm.o
	@rm -f libpptpm.so
	@rm -rf tpm2-tss-4.0.1
	@rm -f tpm2-tss-4.0.1.tar.gz