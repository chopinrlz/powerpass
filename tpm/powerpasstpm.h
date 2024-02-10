/*
    powerpasstpm header file
    Copyright 2023-2024 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

#ifndef POWERPASS_TPM
#define POWERPASS_TPM

#include <stdint.h>

const char __POWERPASS_TEST[]     = "test";
const char __POWERPASS_INIT[]     = "init";
const char __POWERPASS_KEY_PATH[] = "/P_ECCP256SHA256/HS/srk/daltas-powerpass-locker";
const char __POWERPASS_KEY_TYPE[] = "sign,decrypt";

int main(int argc, char** argv);
int pptpm_test(void);
int pptpm_init(void);

#endif