/*
    powerpasstpm main source file
    Copyright 2023-2024 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

// Standard includes
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// PowerPass and tpm2-tss includes
#include "powerpasstpm.h"
#include "tss2/tss2_fapi.h"

/*
    -------------------------------------------------------------------
    Function: int main( int argc, char** argv )
    powerpasstpm main application entry point.
    Command line arguments are as follows:
      test -> tests the connection to the TPM and prints info from FAPI
        Example: ./powerpasstpm test > info.json
        Output: TPM info in JSON format from Fapi_GetInfo
    -------------------------------------------------------------------
*/

int main( int argc, char** argv ) {
    int result = 0;
    if( argc == 2 ) {
        if( strcmp(argv[1],__POWERPASS_TEST) == 0 ) {
            result = pptpm_test();
        }
    } else {
        printf("No arguments specified\n");
    }
    return result;
}

/*
    -------------------------------------------------------------------
    Function: int pptpm_test(void)
    Tests connection to TPM and prints info from TCG Feature API
    -------------------------------------------------------------------
*/

int pptpm_test(void) {
    // Declare context and info variables
    TSS2_RC res;
    FAPI_CONTEXT* context;
    char* info;

    // Initialize the context and check result
    res = Fapi_Initialize( &context, NULL );
    if( res == TSS2_RC_SUCCESS ) {

        // Get all info from the Feature API
        res = Fapi_GetInfo( context, &info );
        if( res != TSS2_FAPI_RC_BAD_REFERENCE ) {
            printf( "%s\n", info );
        } else {
            printf( "{\n\terror: get info returned bad reference\n\tcode: %d\n}", res );
        }

        // Release the context
        Fapi_Finalize( &context );
        return 0;
    } else {
        // Notify user of error
        printf( "{\n\terror: failed to initialize context\n\tcode: %d\n}", res );
        return 1;
    }
}