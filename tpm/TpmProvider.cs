/*
    TpmProvider source code for PowerPass TPM support
    Copyright 2023 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

using System;
using System.Runtime.InteropServices;

namespace PowerPass {
    public class TpmProvider {
        [DllImport("libpptpm.so")]
        public static extern void pptpm_test();

        [DllImport("libpptpm.so")]
        public static extern int pptpm_ver();

        public TpmProvider() { }

        public void Test() { TpmProvider.pptpm_test(); }

        public int Version() { return TpmProvider.pptpm_ver(); }
    }
}