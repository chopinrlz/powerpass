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
// const char __POWERPASS_KEY_PATH[] = "/P_ECCP256SHA256/HS/srk/daltas-powerpass-locker";
const char __POWERPASS_KEY_PATH[] = "/srk/shwatech-test-key";
const char __POWERPASS_KEY_TYPE[] = "sign,decrypt";
const char __POWERPASS_AUTH_LOCKOUT[] = "c5ce0468588540c8979b09fa71e8b11d";

// This secret is generated at deploy-time, it is here for testing only
const char __POWERPASS_AUTH_EH[] = "d87616d200fd45448c58a9303258f9ab";
const char __POWERPASS_AUTH_SH[] = "3ac153cb2dac49e18a148bdd5da9b84f";
const char __POWERPASS_AUTH_SECRET[] = "2ca10696b4a94a8ba732fdd94ea0ef08";

int main(int argc, char** argv);
int pptpm_test(void);
int pptpm_init(void);
TSS2_RC pptpm_provision_authcallback( const char* objectPath, const char* description, const char** auth, void* userData );

#endif