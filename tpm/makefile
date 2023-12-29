SHELL=/bin/bash

powerpasstpm:
	gcc -c -fPIC powerpasstpm.c -o powerpasstpm.o
libpptpm: powerpasstpm
	gcc -shared powerpasstpm.o -o libpptpm.so
install:
	cp -f libpptpm.so /usr/lib
clean:
	rm -f powerpasstpm.o
	rm -f libpptpm.so