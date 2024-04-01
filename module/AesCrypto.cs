/*
    AesCrypto.cs source code for AES block cipher encryption
    Copyright 2023-2024 by ShwaTech LLC
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

using System;
using System.Collections;
using System.IO;
using System.Security.Cryptography;

namespace PowerPass {
    /// <summary>
    /// Implements 256-bit AES encryption and descryption using the file system.
    /// </summary>
    public class AesCrypto : IDisposable {
        
        /// <summary>
        /// This is the private key. It is zeroed out on disposal and destruction.
        /// </summary>
        private byte[] _key = new byte[32];

        /// <summary>
        /// Constructs a new, empty AesCrypto instance.
        /// </summary>
        public AesCrypto() {
            DecryptionBufferSize = (4 * 1024 * 1024);
        }

        /// <summary>
        /// Implements the destructor which zeroes the key bytes from memory.
        /// </summary>
        ~AesCrypto() { Dispose(); }

        /// <summary>
        /// Allows callers to set the symmetric key for encryption or set it to null to erase
        /// it from memory. You should wrap this AesCrypto object in a using statement, or call
        /// Dispose, to ensure the key bytes are zeroed in memory after using this object.
        /// </summary> 
        /// <remarks>Only 32-byte key lengths are supported. If you set this property to a non-null
        /// value, the byte array must be exactly 32-bytes in length.</remarks>
        /// <exception cref="ArgumentException">The value is not exactly 32-bytes.</exception>
        public byte[] Key {
            set {
                if( value != null ) {
                    if( value.Length != 32 ) {
                        throw new ArgumentException( "value must be 32 bytes", "value" );
                    }
                }
                if( _key != null ) ZeroKeyBytes();
                _key = value;
            }
        }

        /// <summary>
        /// Gets or sets the length of the decryption buffer, defaults to 4 MiB.
        /// </summary>
        /// <remarks>
        /// As file contents are decrypted, for each read of the crypto stream a new
        /// buffer is created and then appended to the previous read to form a result.
        /// This is done to ensure that temporary buffers are zeroed out during decryption
        /// to prevent decrypted data from residing in memory after the final result
        /// array of bytes is returned to the caller. This results in a much slower
        /// decryption process, but prevents temporary memory from containing parts of
        /// the decrypted data after the process is complete.
        /// </remarks>
        public int DecryptionBufferSize { get; set; }

        /// <summary>
        /// Creates a new 256-bit encryption key using a cryptographic random number generator.
        /// </summary>
        public void GenerateKey() {
            if( _key != null ) ZeroKeyBytes();
            _key = new byte[32];
            var rng = RandomNumberGenerator.Create();
            rng.GetBytes( _key );
        }

        /// <summary>
        /// Encrypts the specified data, writing to the specified file on disk.
        /// </summary>
        /// <param name="data">The data to encrypt.</param>
        /// <param name="filename">The absolute path of the file on disk to store the encrypted data. If this file
        /// already exists it will be replaced.</param>
        /// <exception cref="ArgumentNullException">The data argument is null.</exception>
        /// <exception cref="ArgumentException">The filename argument is null or empty.</exception> 
        /// <exception cref="InvalidOperationException">No key has been generated, set, or loaded from disk.</exception>
        /// <remarks>
        /// This method does not zero the data array once encryption is complete. It is the responsibility
        /// of the caller to ensure that plain-text data does not remain in memory after storing the data
        /// to the encrypted stream.
        /// </remarks>
        public void Encrypt( byte[] data, string filename ) {
            // Assert preconditions
            if( data == null ) throw new ArgumentNullException( "data" );
            if( _key == null ) throw new InvalidOperationException();
            if( string.IsNullOrEmpty( filename ) ) throw new ArgumentException( "Filename is null or empty", "filename" );

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

        /// <summary>
        /// Decrypts data from the specified file and returns it in a byte array.
        /// </summary>
        /// <param name="filename">The absolute path to the encrypted file.</param>
        /// <returns>The decrypted data.</returns>
        /// <exception cref="InvalidOperationException">No key has been set or loaded from disk.</exception>
        /// <exception cref="ArgumentNullException">The filename argument is null or empty.</exception>
        /// <exception cref="InvalidOperationException">The file specified by filename does not exist.</exception>
        /// <remarks>
        /// As file contents are decrypted, for each read of the crypto stream a new
        /// buffer is created and then appended to the previous read to form a result.
        /// This is done to ensure that temporary buffers are zeroed out during decryption
        /// to prevent decrypted data from residing in memory after the final result
        /// array of bytes is returned to the caller. This results in a much slower
        /// decryption process, but prevents temporary memory from containing parts of
        /// the decrypted data after the process is complete.
        /// </remarks>
        public byte[] Decrypt( string filename ) {
            // Assert preconditions
            if( _key == null ) throw new InvalidOperationException();
            if( string.IsNullOrEmpty( filename ) ) throw new ArgumentNullException( "filename" );
            if( !File.Exists( filename ) ) throw new InvalidOperationException();

            // Decrypt the data stored in the file
            byte[] result = null;
            using( var fs = new FileStream( filename, FileMode.Open ) ) {
                using( var aes = Aes.Create() ) {

                    // Read the initialization vector from the start of the file
                    byte[] iv = new byte[aes.IV.Length];
                    int btr = aes.IV.Length;
                    int index = 0;
                    while( btr > 0 ) {
                        int n = fs.Read( iv, index, btr );
                        if( n == 0 ) break;
                        index += n;
                        btr -= n;
                    }

                    // Decrypt the remaining file contents
                    using( var cs = new CryptoStream( fs, aes.CreateDecryptor( _key, iv ), CryptoStreamMode.Read ) ) {
                        byte[] buffer = new byte[DecryptionBufferSize];
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

                        // Zero the buffer
                        for( int i = 0; i < buffer.Length; i++ ) {
                            buffer[i] = 0x00;
                        }
                    }
                }
            }
            return result;
        }

        /// <summary>
        /// Loads an encryption key from disk into this AesCrypto instance for encryption and decryption.
        /// </summary>
        /// <param name="filename">The absolute path to the key file.</param>
        /// <param name="secret">The secret used to decrypt the key. This must be 32 bytes. The contents of this array will be erased.</param>
        /// <exception cref="ArgumentNullException">The filename or secret are null or empty.</exception>
        /// <exception cref="ArgumentException">The filename does not exist on disk or the secret length is incorrect.</exception>
        public void ReadKeyFromDisk( string filename, ref byte[] secret ) {
            // Assert preconditions
            if( string.IsNullOrEmpty( filename ) ) throw new ArgumentNullException( "filename" );
            if( !File.Exists( filename ) ) throw new ArgumentException( "filename does not exist", "filename" );
            if( secret == null ) throw new ArgumentNullException( "secret" );
            if( secret.Length != 32 ) throw new ArgumentException( "secret must be 32 bytes", "secret" );

            // Decrypt the key using the passphrase
            using( var aes = new AesCrypto() ) {
                aes.Key = secret;
                this.Key = aes.Decrypt( filename );
            }
        }

        /// <summary>
        /// Saves the current key to disk. If no key has been set, a key will be generated.
        /// </summary>
        /// <param name="filename">The absolute path to the file to write to disk.</param>
        /// <param name="secret">The secret used to encrypt the key. Must be 32 characters. The contents of this array will be erased.</param>
        /// <exception cref="ArgumentNullException">The filename or secret are null or empty.</exception>
        /// <exception cref="ArgumentException">The passphrase length is incorrect.</exception>
        /// <remarks>
        /// If the file already exists on disk, it will be deleted first.
        /// </remarks>
        public void WriteKeyToDisk( string filename, ref byte[] secret ) {
            // Assert preconditions
            if( string.IsNullOrEmpty( filename ) ) throw new ArgumentNullException( "filename" );
            if( secret == null ) throw new ArgumentNullException( "secret" );
            if( secret.Length != 32 ) throw new ArgumentException( "secret must be 32 bytes", "secret" );

            // Generate a key if there isn't one already
            if( _key == null ) GenerateKey();

            // Write the key file to disk, deleting an existing one
            if( File.Exists( filename ) ) File.Delete( filename );
            using( var aes = new AesCrypto() ) {
                aes.Key = secret;
                aes.Encrypt( _key, filename );
            }
        }

        /// <summary>
        /// Creates a 256-bit AES key from a password.
        /// </summary>
        /// <param name="secret">Any secret between 4 and 32 characters in length.</param>
        /// <returns>A UTF-8 encoded 32-length byte array with the password.</returns>
        /// <exception cref="ArgumentNullException">The secret is null or empty.</exception>
        /// <exception cref="ArgumentException">The secret is the incorrect length.</exception>
        public static byte[] CreatePaddedKey( string secret ) {
            // Assert pre-conditions
            if( string.IsNullOrEmpty( secret ) ) throw new ArgumentNullException( "secret" );
            if( secret.Length < 4 || secret.Length > 32 ) throw new ArgumentException( "secret must be between 4 and 32 characters", "secret" );

            // Generate the byte array from the password
            var pb = System.Text.Encoding.UTF8.GetBytes( secret );
            if( pb.Length < 32 ) {
                var pbNew = new byte[32];
                Array.Copy( pb, 0, pbNew, 0, pb.Length );
                for( int i = pb.Length; i < 32; i++ ) {
                    pbNew[i] = pb[i % pb.Length];
                }
                for( int i = 0; i < pb.Length; i++ ) {
                    pb[i] = 0;
                }
                pb = pbNew;
            }
            return pb;
        }

        /// <summary>
        /// Sets the key to a secret passphrase.
        /// </summary>
        /// <param name="secret">The secret passphrase to use as the key. Must be between 4 and 32 characters in length.</param>
        /// <exception cref="ArgumentNullException">The secret argument is null or empty.</exception>
        /// <exception cref="ArgumentException">The secret length is incorrect.</exception>
        public void SetPaddedKey( string secret ) {
            // Assert pre-conditions
            if( string.IsNullOrEmpty( secret ) ) throw new ArgumentNullException( "secret" );
            if( secret.Length < 4 || secret.Length > 32 ) throw new ArgumentException( "secret must be between 4 and 32 characters", "secret" );

            // Update the key
            if( _key != null ) ZeroKeyBytes();
            _key = CreatePaddedKey( secret );
        }

        /// <summary>
        /// Zeroes out the key bytes from memory.
        /// </summary>
        public void Dispose() {
            if( _key != null ) {
                ZeroKeyBytes();
            }
        }

        /// <summary>
        /// Zeroes out the key bytes from memory.
        /// </summary>
        private void ZeroKeyBytes() {
            for( int i = 0; i < _key.Length; i++ ) {
                _key[i] = 0x00;
            }
        }
    }
}