using System;

namespace PowerPass {
    public class TpmProvider {
        [DllImport("powerpasstpm.so")]
        public static extern void pptpm_test();

        public TpmProvider() { }

        public void Test() { pptpm_test(); }
    }
}