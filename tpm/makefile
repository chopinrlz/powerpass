# makefile for building and installing libpptpm
# Copyright 2023 by The Daltas Group LLC.
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
SHELL=/bin/bash

LIB_DIR := /usr/lib
NPROC != nproc

# Instructions:
# make
# sudo make install-tpm2-tss
# make library
# sudo make install

tpm2-tss-make: tpm2-tss
	tar -xv -f tpm2-tss-4.0.1.tar.gz
	cd ./tpm2-tss-4.0.1/; ./configure --prefix=/usr; make -j$(NPROC)
download:
	curl -LO https://github.com/tpm2-software/tpm2-tss/releases/download/4.0.1/tpm2-tss-4.0.1.tar.gz
tpm2-tss:
	touch tpm2-tss-4.0.1.tar.gz
install-tpm2-tss: tpm2-tss-make
	cd ./tpm2-tss-4.0.1/; make install
library: compile
	gcc -shared powerpasstpm.o -o libpptpm.so
compile:
	mkdir headers
	cp -rf ./tpm2-tss-4.0.1/include .
	gcc -c -fPIC powerpasstpm.c -o powerpasstpm.o
install: library
	cp -f libpptpm.so $(LIB_DIR)
clean:
	@rm -f powerpasstpm.o
	@rm -f libpptpm.so
	@rm -rf tpm2-tss-4.0.1
	@rm -f tpm2-tss-4.0.1.tar.gz
	@rm -rf include