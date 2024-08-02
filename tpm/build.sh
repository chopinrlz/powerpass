#!/bin/bash
sudo make depends
make tpm2-tss-release
cd tpm2-tss
sudo make install
cd ..
sudo make post
make perms
