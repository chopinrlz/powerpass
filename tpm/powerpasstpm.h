/*
    powerpasstpm header file
    Copyright 2023-2024 by ShwaTech LLC
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

#ifndef POWERPASS_TPM
#define POWERPASS_TPM

#include <stdint.h>
#include "tss2/tss2_rc.h"

const char __POWERPASS_TEST[]     = "test";
const char __POWERPASS_INIT[]     = "init";
const char __POWERPASS_ENC[]      = "enc";

const char __POWERPASS_KEY_PATH[] = "/P_RSA2048SHA256/HS/shwatech-powerpass";
const char __POWERPASS_KEY_TYPE[] = "sign,decrypt";

// Two secrets for testing purposes on temporary powerpass Ubuntu virtual machine
// These are generated using [Guid]::NewGuid().ToLower().Replace("-","") to create
// two random 256-bit secrets. The Lockout value is used as the lockout authorization
// value during Fapi_Provision. The Secret value is passed to the FAPI during the
// callback function when the FAPI is requesting an authorization value.
const char __POWERPASS_AUTH_LOCKOUT[] = "cf277f486f6545d1ba8de14b8ddb6dda";
const char __POWERPASS_AUTH_SECRET[]  = "35b5835b28fe42d09746c6c0d486381d";

// Function declarations
int main(int argc, char** argv);
int pptpm_test(void);
int pptpm_init(void);
TSS2_RC pptpm_provision_authcallback( const char* objectPath, const char* description, const char** auth, void* userData );
int pptpm_echo(TSS2_RC res);
void pptpm_print(uint8_t* bytes, size_t len);
int pptpm_enc(void);

#endif // #define POWERPASS_TPM