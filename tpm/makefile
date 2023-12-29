# makefile for building and installing libpptpm
# Copyright 2023 by The Daltas Group LLC.
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
SHELL=/bin/bash

LIB_DIR := /usr/lib

libpptpm: powerpasstpm
	curl -LO https://github.com/tpm2-software/tpm2-tss/releases/download/4.0.1/tpm2-tss-4.0.1.tar.gz
	gcc -shared powerpasstpm.o -o libpptpm.so
powerpasstpm:
	gcc -c -fPIC powerpasstpm.c -o powerpasstpm.o
install: libpptpm
	cp -f libpptpm.so $(LIB_DIR)
clean:
	@rm -f powerpasstpm.o
	@rm -f libpptpm.so