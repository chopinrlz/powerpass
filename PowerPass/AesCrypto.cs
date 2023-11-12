using System;
using System.Collections;
using System.IO;
using System.Security.Cryptography;

namespace PowerPass {
    public class AesCrypto : IDisposable {
        
        private byte[] _key = new byte[32];

        public AesCrypto() { }

        ~AesCrypto() {
            if( _key != null ) ZeroKeyBytes();
        }

        /// <summary>
        /// Gets or sets the symmetric key for encryption.
        /// </summary>
        public byte[] Key {
            get {
                return _key;
            }
            set {
                if( _key != null ) ZeroKeyBytes();
                _key = value;
            }
        }

        /// <summary>
        /// Creates a new 256-bit encryption key.
        /// </summary>
        public void GenerateKey() {
            if( _key != null ) ZeroKeyBytes();
            _key = new byte[32];
            var rng = RandomNumberGenerator.Create();
            rng.GetBytes( _key );
        }

        public void Encrypt( byte[] data, string filename ) {
            // Assert preconditions
            if( data == null ) throw new ArgumentNullException( "data" );
            if( _key == null ) throw new InvalidOperationException();
            if( string.IsNullOrEmpty( filename ) ) throw new InvalidOperationException();

            // Delete existing file
            if( File.Exists( filename ) ) {
                File.Delete( filename );
            }

            // Write encrypted stream
            using( var fs = new FileStream( filename, FileMode.Create ) ) {
                using( var aes = Aes.Create() ) {
                    aes.Key = _key;
                    byte[] iv = aes.IV;
                    fs.Write( iv, 0, iv.Length );
                    using( var cs = new CryptoStream( fs, aes.CreateEncryptor(), CryptoStreamMode.Write ) ) {
                        cs.Write( data, 0, data.Length );
                    }
                }
            }
        }

        public byte[] Decrypt( string filename ) {
            // Assert preconditions
            if( _key == null ) throw new InvalidOperationException();
            if( string.IsNullOrEmpty( filename ) ) throw new InvalidOperationException();
            if( !File.Exists( filename ) ) throw new InvalidOperationException();

            // Decrypt the data stored in the file
            byte[] result = null;
            try {
            using( var fs = new FileStream( filename, FileMode.Open ) ) {
                using( var aes = Aes.Create() ) {
                    byte[] iv = new byte[aes.IV.Length];
                    int btr = aes.IV.Length;
                    int index = 0;
                    while( btr > 0 ) {
                        int n = fs.Read( iv, index, btr );
                        if( n == 0 ) break;
                        index += n;
                        btr -= n;
                    }
                    using( var cs = new CryptoStream( fs, aes.CreateDecryptor( _key, iv ), CryptoStreamMode.Read ) ) {
                        byte[] buffer = new byte[1024];
                        int read = cs.Read( buffer, 0, buffer.Length );
                        int total = 0;
                        while( read > 0 ) {
                            total += read;
                            if( result == null ) { 
                                result = new byte[read];
                                Array.Copy( buffer, result, read );
                            } else {
                                byte[] newResult = new byte[total];
                                Array.Copy( result, newResult, result.Length );
                                Array.Copy( buffer, 0, newResult, result.Length, read );
                                for( int i = 0; i < result.Length; i++ ) {
                                    result[i] = 0x00;
                                }
                                result = newResult;
                            }
                            read = cs.Read( buffer, 0, buffer.Length );
                        }
                        for( int i = 0; i < buffer.Length; i++ ) {
                            buffer[i] = 0x00;
                        }
                    }
                }
            } } catch(Exception ex) { Console.WriteLine(ex.StackTrace);}
            return result;
        }

        public void ReadKeyFromDisk( string filename ) {
            if( string.IsNullOrEmpty( filename ) ) throw new ArgumentNullException( "filename" );
            if( !File.Exists( filename ) ) throw new InvalidOperationException();

            using( var fs = new FileStream( filename, FileMode.Open ) ) {
                if( fs.Length < 32 ) throw new InvalidOperationException();
                int total = 32;
                _key = new byte[32];
                int index = 0;
                int read = fs.Read( _key, index, 32 );
                total -= read;
                index += read;
                while( total > 0 ) {
                    read = fs.Read( _key, index, 32 - total );
                    total -= read;
                }
            }
        }

        public void WriteKeyToDisk( string filename ) {
            if( string.IsNullOrEmpty( filename ) ) throw new InvalidOperationException();
            if( _key == null ) GenerateKey();
            if( File.Exists( filename ) ) File.Delete( filename );
            using( var fs = new FileStream( filename, FileMode.Create ) ) {
                fs.Write( _key, 0, _key.Length );
                fs.Flush();
            }
        }

        public void Dispose() {
            if( _key != null ) {
                ZeroKeyBytes();
            }
        }

        private void ZeroKeyBytes() {
            for( int i = 0; i < _key.Length; i++ ) {
                _key[i] = 0x00;
            }
        }
    }
}