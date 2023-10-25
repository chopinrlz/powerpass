using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;

namespace PowerPass
{
    public sealed class DataProtection
    {
        public DataProtection()
        {

        }

        /// <summary>
        /// Creates 256 bits of random entropy.
        /// </summary>
        /// <returns>A byte array with 256 bits of random entropy for salting.</returns>
        public static byte[] CreateRandomEntropy()
        {
            byte[] entropy = new byte[32];
            new RNGCryptoServiceProvider().GetBytes(entropy);
            return entropy;
        }
    }
}