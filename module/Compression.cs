using System;
using System.IO;
using System.IO.Compression;
using System.Text;

namespace PowerPass {
	public static class Compressor {
		public static byte[] CompressFromDisk( string file ) {
			using( MemoryStream ms = new MemoryStream() ) {
				using( FileStream fs = File.OpenRead( file ) ) {
					using( GZipStream gz = new GZipStream( ms, CompressionMode.Compress ) ) {
						fs.CopyTo( gz );
					}
				}
				return ms.ToArray();
			}
		}

		public static byte[] DecompressFromBase64( string data ) {
			using( MemoryStream ms = new MemoryStream() ) {
				using( MemoryStream cd = new MemoryStream() ) {
					byte[] data = Convert.FromBase64String( data );
					cd.Write( data, 0, data.Length );
					cd.Position = 0;
					using( GZipStream gz = new GZipStream( ms, CompressionMode.Decompress ) ) {
						cd.CopyTo( gz );
					}
				}
				return ms.ToArray();
			}
		}
	}
}