/*  libpptpm header file
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0. */

#ifndef POWERPASS_TPM
#define POWERPASS_TPM

#include <stdint.h>

int main(void);
void pptpm_test(void);
int pptpm_ver(void);
uint32_t pptpm_exec(void);

#endif