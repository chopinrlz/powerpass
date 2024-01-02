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
        [DllImport("/usr/lib/libpptpm.so")]
        public static extern void pptpm_test();

        [DllImport("/usr/lib/libpptpm.so")]
        public static extern int pptpm_ver();

        [DllImport("/usr/lib/libpptpm.so")]
        public static extern UInt32 pptpm_exec();

        public TpmProvider() { }

        public void Test() { TpmProvider.pptpm_test(); }

        public int Version() { return TpmProvider.pptpm_ver(); }

        public uint Execute() { return TpmProvider.pptpm_exec(); }
    }
}