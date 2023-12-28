release:
echo 'Building libpptpm.so'
rm -f powerpasstpm.o
rm -f libpptpm.so
gcc -c -fPIC powerpasstpm.c -o powerpasstpm.o
gcc -shared powerpasstpm.o -o libpptpm.so
cp -f libpptpm.so /usr/lib