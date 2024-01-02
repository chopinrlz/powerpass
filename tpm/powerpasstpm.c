/*  libpptpm main source file
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0. */

#include <stdio.h>
#include <string.h>

#include "powerpasstpm.h"
#include "include/tss2/tss2_fapi.h"

void pptpm_test() {
    printf("Success\n");
}

int pptpm_ver() {
    return 150;
}

uint32_t pptpm_exec() {
    printf("Init context\n");
    FAPI_CONTEXT** context;
    printf("Fapi_Initalize\n");
    TSS2_RC res = Fapi_Initialize( context, NULL );
    printf("Fapi_Free");
    Fapi_Free(context);
    return res;
}