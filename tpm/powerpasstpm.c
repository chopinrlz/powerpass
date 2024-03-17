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
#include "tss2/tss2_rc.h"

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
    if( argc > 1 ) {
        if( strcmp(argv[1],__POWERPASS_TEST) == 0 ) {
            result = pptpm_test();
        }
        if( strcmp(argv[1],__POWERPASS_INIT) == 0 ) {
            result = pptpm_init();
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
            Fapi_Free( info );
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

/*
    -------------------------------------------------------------------
    Function: int pptpm_init(void)
    Initializes the PowerPass Locker key in the TPM
    -------------------------------------------------------------------
*/

int pptpm_init(void) {
    TSS2_RC res;
    FAPI_CONTEXT* context;
    res = Fapi_Initialize( &context, NULL );
    if( res == TSS2_RC_SUCCESS ) {
        res = Fapi_Provision( context, NULL, NULL, __POWERPASS_AUTH_LOCKOUT );
        if( res == TSS2_RC_SUCCESS ) {
            res = Fapi_CreateKey( context, __POWERPASS_KEY_PATH, __POWERPASS_KEY_TYPE, NULL, NULL );
            switch( res ) {
                case TSS2_RC_SUCCESS:
                    printf( "Successfully created key at %s\n", __POWERPASS_KEY_PATH );
                    break;
                case TSS2_FAPI_RC_PATH_ALREADY_EXISTS:
                    printf( "Key already exists\n" );
                    break;
                default:
                    printf( "Error creating TPM key for PowerPass Locker\n" );
                    break;
            }
        } else {
            printf( "Error provisioning Feature API instance: %d\n", res );
        }
        Fapi_Finalize( &context );
    } else {
        printf( "Error initializing FAPI context\n" );
    }

    // Check return code
    if( res != TSS2_RC_SUCCESS ) {
        const char* decoded = Tss2_RC_Decode( res );
        printf( "Decoded error message: %s\n", decoded );
        return 1;
    } else {
        return 0;
    }
}