/*
    Compression.cs source code for GZip compression and decompression of files on disk.
    Copyright 2023-2025 by ShwaTech LLC
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

using System;
using System.IO;
using System.IO.Compression;

namespace PowerPass {

	/// <summary>
	/// Provides a simple API for applying GZip compression to files on disk.
	/// </summary>
	public static class Compressor {

		/// <summary>
		/// Compresses a file on disk using GZip and returns the compressed file as a byte array.
		/// </summary>
		/// <param name="file">The full path of the file on disk.</param>
		/// <returns>The GZip compressed array of bytes for the file.</returns>
		public static byte[] CompressFromDisk( string file ) {
			// Asserts
			if( String.IsNullOrEmpty( file ) ) throw new ArgumentNullException( "file" );
			if( !File.Exists( file ) ) throw new ArgumentException( "File does not exist" );

			// Load the file and compress it to an in-memory stream
			using( MemoryStream ms = new MemoryStream() ) {
				using( FileStream fs = File.OpenRead( file ) ) {
					using( GZipStream gz = new GZipStream( ms, CompressionMode.Compress ) ) {
						fs.CopyTo( gz );
					}
				}
				return ms.ToArray();
			}
		}

		/// <summary>
		/// Decompresses a GZip file from a base64 string.
		/// </summary>
		/// <param name="data">The GZip compressed file bytes</param>
		/// <returns>The decompressed file bytes.</returns>
		public static byte[] DecompressBytes( byte[] data ) {
			// Asserts
			if( data == null ) throw new ArgumentNullException( "data" );
			if( data.Length <= 0 ) throw new ArgumentNullException( "data" );

			// Decompress the data to a byte array
			using( MemoryStream ms = new MemoryStream() ) {
				using( MemoryStream cd = new MemoryStream() ) {
					cd.Write( data, 0, data.Length );
					cd.Position = 0;
					using( GZipStream gz = new GZipStream( cd, CompressionMode.Decompress ) ) {
						gz.CopyTo( ms );
					}
				}
				return ms.ToArray();
			}
		}
	}
}