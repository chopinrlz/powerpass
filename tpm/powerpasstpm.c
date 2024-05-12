/*
    powerpasstpm main source file
    Copyright 2023-2024 by ShwaTech LLC
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
        if( strcmp(argv[1],__POWERPASS_ENC) == 0 ) {
            result = pptpm_enc();
        }
    } else {
        printf("No arguments specified\n");
    }
    return result;
}

/*
    -------------------------------------------------------------------
    Function: int pptpm_echo( TPM2_RC )
    Checks the TPM2 return code and prints and decodes and error message
    if the value is not TSS2_RC_SUCCESS then returns either 1 or 0.
    -------------------------------------------------------------------
*/

int pptpm_echo( TPM2_RC res ) {
    if( res != TSS2_RC_SUCCESS ) {
        const char* decoded = Tss2_RC_Decode( res );
        printf( "powerpasstpm: TPM2_RC code: %d\n", res );
        printf( "powerpasstpm: Decoded error message: %s\n", decoded );
        return 1;
    } else {
        return 0;
    }
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
    } else {
        // Notify user of error
        printf( "{\n\terror: failed to initialize context\n\tcode: %d\n}", res );
    }

    // Check return code
    return (pptpm_echo(res));
}

/*
    -------------------------------------------------------------------
    Function: int pptpm_init(void)
    Initializes the PowerPass Locker key in the TPM
    -------------------------------------------------------------------
*/

int pptpm_init(void) {
    // Declare context and return code variables
    TSS2_RC res;
    FAPI_CONTEXT* context;

    // Initialize the context
    printf( "powerpasstpm: calling Fapi_Initialize\n" );
    res = Fapi_Initialize( &context, NULL );
    if( res == TSS2_RC_SUCCESS ) {

        // Set the callback for authorization value retrieval
        printf( "powerpasstpm: calling Fapi_SetAuthCB\n" );
        res = Fapi_SetAuthCB( context, pptpm_provision_authcallback, NULL );
        if( res == TSS2_RC_SUCCESS ) {

            // Provision the FAPI context
            printf( "powerpasstpm: calling Fapi_Provision\n" );
            res = Fapi_Provision( context, NULL, NULL, __POWERPASS_AUTH_LOCKOUT );

            // Create the root storage hierarchy key
            if( res == TSS2_RC_SUCCESS || res == TSS2_FAPI_RC_ALREADY_PROVISIONED ) {
                printf( "powerpasstpm: calling Fapi_CreateKey for srk\n" );
                res = Fapi_CreateKey( context, __POWERPASS_KEY_ROOT, __POWERPASS_KEY_RKTP, NULL, NULL );
            }

            // Create the PowerPass encryption key
            if( res == TSS2_RC_SUCCESS || res == TSS2_FAPI_RC_PATH_ALREADY_EXISTS ) {
                printf( "powerpasstpm: calling Fapi_CreateKey for powerpass\n" );
                res = Fapi_CreateKey( context, __POWERPASS_KEY_PATH, __POWERPASS_KEY_TYPE, NULL, NULL );
            }
        } else {
            printf( "powerpasstpm: Error setting auth callback\n" );
        }
        
        // Release the context
        Fapi_Finalize( &context );
    } else {
        printf( "powerpasstpm: Error initializing FAPI context\n" );
    }

    // Check return code
    return (pptpm_echo(res));
}

/*
    -------------------------------------------------------------------
    Function: TSS2_RC pptpm_provision_authcallback
    Handles the callback to provide an authorization value (password)
    for the storage hierarchy during FAPI provisioning.
    -------------------------------------------------------------------
*/

TSS2_RC pptpm_provision_authcallback( const char* objectPath, const char* description, const char** auth, void* userData ) {
    if( !objectPath ) {
        printf( "powerpasstpm: authcallback has no objectPath\n" );
        return TSS2_FAPI_RC_BAD_VALUE;
    } else {
        printf( "powerpasstpm: Auth callback invoked for %s\n", objectPath );
        if( description ) {
            printf( "powerpasstpm: Auth callback description: %s\n", description );
        }
        *auth = __POWERPASS_AUTH_SECRET;
        return TSS2_RC_SUCCESS;
    }
}

/*
    -------------------------------------------------------------------
    Function: int pptpm_enc(void)
    Encrypts data using a TPM key.
    -------------------------------------------------------------------
*/

int pptpm_enc(void) {
    // Declare context and return code variables
    TSS2_RC res;
    FAPI_CONTEXT* context;

    // Initialize the context
    printf( "powerpasstpm: calling Fapi_Initialize\n" );
    res = Fapi_Initialize( &context, NULL );
    if( res == TSS2_RC_SUCCESS ) {

        // Make some data
        size_t buflen = 128;
        uint8_t ptext[128];
        for( int i = 0; i < 128; i++ ) {
            ptext[i] = (uint8_t)i;
        }
        printf( "powerpasstpm: plain-text string: %s\n", ptext );

        // Encrypt the data
        uint8_t* encdata;
        size_t enclen;
        res = Fapi_Encrypt( context, __POWERPASS_KEY_ROOT, ptext, buflen, &encdata, &enclen );
        if( res == TSS2_RC_SUCCESS ) {
            printf( "powerpasstpm: encryption successful\n" );
            printf( "powerpasstpm: encrypted string: %s\n", encdata );
        } else {
            printf( "powerpasstpm: encryption failed\n" );
        }
        
        // Release the encryption buffer
        Fapi_Free( encdata );

        // Release the context
        Fapi_Finalize( &context );
    } else {
        printf( "powerpasstpm: failed to initialize FAPI context\n" );
    }

    // Check return code
    return (pptpm_echo(res));
}