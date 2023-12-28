using System;
using System.Runtime.InteropServices;

namespace PowerPass {
    public class TpmProvider {
        [DllImport("libpptpm.so")]
        public static extern void pptpm_test();

        public TpmProvider() { }

        public void Test() { pptpm_test(); }
    }
}