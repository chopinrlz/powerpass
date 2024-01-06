/*
    Extensions.cs source code for extending functionality into other types
    Copyright 2023-2024 by The Daltas Group LLC.
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

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