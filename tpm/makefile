SHELL=/bin/bash

libpptpm: powerpasstpm
	gcc -shared powerpasstpm.o -o libpptpm.so
powerpasstpm:
	gcc -c -fPIC powerpasstpm.c -o powerpasstpm.o
install: libpptpm
	cp -f libpptpm.so /usr/lib
clean:
	@rm -f powerpasstpm.o
	@rm -f libpptpm.so