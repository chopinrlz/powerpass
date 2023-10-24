using System;
using System.Runtime.InteropServices;
using System.Security;
using System.Text;
using KeePassLib.Keys;

namespace PowerPass
{
    public static class Extensions
    {
        public static KcpPassword CreateKcpPassword(SecureString secureString)
        {
            IntPtr valuePtr = IntPtr.Zero;
            try
            {
                valuePtr = Marshal.SecureStringToGlobalAllocUnicode(secureString);
                byte[] ptBytes = Encoding.UTF8.GetBytes(Marshal.PtrToStringUni(valuePtr));
                return new KcpPassword(ptBytes);
            }
            finally
            {
                Marshal.ZeroFreeGlobalAllocUnicode(valuePtr);
            }
        }
    }
}