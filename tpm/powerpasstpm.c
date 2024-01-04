/*  libpptpm main source file
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0. */

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "powerpasstpm.h"
#include "tss2/tss2_fapi.h"

int main(int argc, char** argv) {
    if( argc == 2 ) {
        if( strcmp(argv[1],__POWERPASS_TEST) == 0 ) {
            printf("Running test\n");
            FAPI_CONTEXT** context;
            printf("Calling Fapi_Initialize");
            TSS2_RC res = Fapi_Initialize( context, NULL );
            printf("Calling Fapi_Finalize");
            Fapi_Finalize(context);
            printf("Calling Fapi_Free");
            Fapi_Free(context);
            printf("Context initialize result %d\n",res);
        }
    } else {
        printf("No arguments specified\n");
    }
    return 0;
}

void pptpm_test(void) {
    printf("Success\n");
}

int pptpm_ver(void) {
    return 150;
}

uint32_t pptpm_exec(void) {
    printf("Init context\n");
    FAPI_CONTEXT** context;
    printf("Fapi_Initalize\n");
    TSS2_RC res = Fapi_Initialize( context, NULL );
    printf("Fapi_Finalize");
    Fapi_Finalize(context);
    printf("Fapi_Free");
    Fapi_Free(context);
    return res;
}