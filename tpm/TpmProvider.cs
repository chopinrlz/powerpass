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