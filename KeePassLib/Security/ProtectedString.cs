/*
  KeePass Password Safe - The Open-Source Password Manager
  Copyright (C) 2003-2025 Dominik Reichl <dominik.reichl@t-online.de>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

using System;
using System.Diagnostics;
using System.Text;

using KeePassLib.Cryptography;
using KeePassLib.Utility;

#if KeePassLibSD
using KeePassLibSD;
#endif

// SecureString objects are limited to 65536 characters, don't use

namespace KeePassLib.Security
{
	/// <summary>
	/// A string that is protected in process memory.
	/// <c>ProtectedString</c> objects are immutable and thread-safe.
	/// </summary>
#if (DEBUG && !KeePassLibSD)
	[DebuggerDisplay("{ReadString()}")]
#endif
	public sealed class ProtectedString
	{
		// Exactly one of the following will be non-null
		private ProtectedBinary m_pbUtf8 = null;
		private string m_strPlainText = null;

		private bool m_bIsProtected;

		private static readonly ProtectedString m_psEmpty = new ProtectedString();
		/// <summary>
		/// Get an empty <c>ProtectedString</c> object, without protection.
		/// </summary>
		public static ProtectedString Empty
		{
			get { return m_psEmpty; }
		}

		private static readonly ProtectedString m_psEmptyEx = new ProtectedString(
			true, new byte[0]);
		/// <summary>
		/// Get an empty <c>ProtectedString</c> object, with protection turned on.
		/// </summary>
		public static ProtectedString EmptyEx
		{
			get { return m_psEmptyEx; }
		}

		/// <summary>
		/// A flag specifying whether the <c>ProtectedString</c> object
		/// has turned on memory protection or not.
		/// </summary>
		public bool IsProtected
		{
			get { return m_bIsProtected; }
		}

		public bool IsEmpty
		{
			get
			{
				ProtectedBinary p = m_pbUtf8; // Local ref for thread-safety
				if(p != null) return (p.Length == 0);

				Debug.Assert(m_strPlainText != null);
				return (m_strPlainText.Length == 0);
			}
		}

		private int m_nCachedLength = -1;
		/// <summary>
		/// Length of the protected string, in characters.
		/// </summary>
		public int Length
		{
			get
			{
				if(m_nCachedLength >= 0) return m_nCachedLength;

				ProtectedBinary p = m_pbUtf8; // Local ref for thread-safety
				if(p != null)
				{
					byte[] pbPlain = p.ReadData();
					try { m_nCachedLength = StrUtil.Utf8.GetCharCount(pbPlain); }
					finally { MemUtil.ZeroByteArray(pbPlain); }
				}
				else
				{
					Debug.Assert(m_strPlainText != null);
					m_nCachedLength = m_strPlainText.Length;
				}

				return m_nCachedLength;
			}
		}

		/// <summary>
		/// Construct a new protected string. Protection is disabled.
		/// </summary>
		public ProtectedString()
		{
			Init(false, string.Empty);
		}

		/// <summary>
		/// Construct a new protected string.
		/// </summary>
		/// <param name="bEnableProtection">Specifies whether to encrypt the
		/// data in the process memory.</param>
		/// <param name="strValue">The string value.</param>
		public ProtectedString(bool bEnableProtection, string strValue)
		{
			Init(bEnableProtection, strValue);
		}

		/// <summary>
		/// Construct a new protected string.
		/// </summary>
		/// <param name="bEnableProtection">Specifies whether to encrypt the
		/// data in the process memory.</param>
		/// <param name="vUtf8Value">The string value, encoded as UTF-8 byte
		/// array. The <c>ProtectedString</c> object does not modify or take
		/// ownership of the data, i.e. the caller is responsible for clearing it.</param>
		public ProtectedString(bool bEnableProtection, byte[] vUtf8Value)
		{
			Init(bEnableProtection, vUtf8Value);
		}

		/// <summary>
		/// Construct a new protected string.
		/// </summary>
		/// <param name="bEnableProtection">Specifies whether to encrypt the
		/// data in the process memory.</param>
		/// <param name="xb"><c>XorredBuffer</c> object containing the string
		/// in UTF-8 representation. The UTF-8 string must not be null-terminated.</param>
		public ProtectedString(bool bEnableProtection, XorredBuffer xb)
		{
			if(xb == null) { Debug.Assert(false); throw new ArgumentNullException("xb"); }

			byte[] pb = xb.ReadPlainText();
			try { Init(bEnableProtection, pb); }
			finally { if(bEnableProtection) MemUtil.ZeroByteArray(pb); }
		}

		private void Init(bool bEnableProtection, string str)
		{
			if(str == null) throw new ArgumentNullException("str");

			m_bIsProtected = bEnableProtection;

			// As the string already is in memory and immutable,
			// protection would be useless
			m_strPlainText = str;
		}

		private void Init(bool bEnableProtection, byte[] pbUtf8)
		{
			if(pbUtf8 == null) throw new ArgumentNullException("pbUtf8");

			m_bIsProtected = bEnableProtection;

			if(bEnableProtection)
				m_pbUtf8 = new ProtectedBinary(true, pbUtf8);
			else
				m_strPlainText = StrUtil.Utf8.GetString(pbUtf8, 0, pbUtf8.Length);
		}

		/// <summary>
		/// Convert the protected string to a standard string object.
		/// Be careful with this function, as the returned string object
		/// isn't protected anymore and stored in plain-text in the
		/// process memory.
		/// </summary>
		/// <returns>Plain-text string. Is never <c>null</c>.</returns>
		public string ReadString()
		{
			if(m_strPlainText != null) return m_strPlainText;

			byte[] pb = ReadUtf8();
			string str = ((pb.Length == 0) ? string.Empty :
				StrUtil.Utf8.GetString(pb, 0, pb.Length));
			// No need to clear pb

			// As the text is now visible in process memory anyway,
			// there's no need to protect it anymore (strings are
			// immutable and thus cannot be overwritten)
			m_strPlainText = str;
			m_pbUtf8 = null; // Thread-safe order

			return str;
		}

		/// <summary>
		/// Read out the string and return it as a char array.
		/// The returned array is not protected and should be cleared by
		/// the caller.
		/// </summary>
		/// <returns>Plain-text char array.</returns>
		public char[] ReadChars()
		{
			if(m_strPlainText != null) return m_strPlainText.ToCharArray();

			byte[] pb = ReadUtf8();
			try { return StrUtil.Utf8.GetChars(pb); }
			finally { MemUtil.ZeroByteArray(pb); }
		}

		/// <summary>
		/// Read out the string and return a byte array that contains the
		/// string encoded using UTF-8.
		/// The returned array is not protected and should be cleared by
		/// the caller.
		/// </summary>
		/// <returns>Plain-text UTF-8 byte array.</returns>
		public byte[] ReadUtf8()
		{
			ProtectedBinary p = m_pbUtf8; // Local ref for thread-safety
			if(p != null) return p.ReadData();

			return StrUtil.Utf8.GetBytes(m_strPlainText);
		}

		/// <summary>
		/// Get the string as an UTF-8 sequence xorred with bytes
		/// from a <c>CryptoRandomStream</c>.
		/// </summary>
		public byte[] ReadXorredString(CryptoRandomStream crsRandomSource)
		{
			if(crsRandomSource == null) { Debug.Assert(false); throw new ArgumentNullException("crsRandomSource"); }

			byte[] pbData = ReadUtf8();
			int cb = pbData.Length;

			byte[] pbPad = crsRandomSource.GetRandomBytes((uint)cb);
			Debug.Assert(pbPad.Length == cb);

			for(int i = 0; i < cb; ++i)
				pbData[i] ^= pbPad[i];

			MemUtil.ZeroByteArray(pbPad);
			return pbData;
		}

		public ProtectedString WithProtection(bool bProtect)
		{
			if(bProtect == m_bIsProtected) return this;

			byte[] pb = ReadUtf8();

			// No need to clear pb; either the current or the new object is unprotected
			return new ProtectedString(bProtect, pb);
		}

		public bool Equals(ProtectedString ps, bool bCheckProtEqual)
		{
			if(ps == null) throw new ArgumentNullException("ps");
			if(object.ReferenceEquals(this, ps)) return true; // Perf. opt.

			bool bPA = m_bIsProtected, bPB = ps.m_bIsProtected;
			if(bCheckProtEqual && (bPA != bPB)) return false;
			if(!bPA && !bPB) return (ReadString() == ps.ReadString());

			byte[] pbA = ReadUtf8(), pbB = null;
			bool bEq;
			try
			{
				pbB = ps.ReadUtf8();
				bEq = MemUtil.ArraysEqual(pbA, pbB);
			}
			finally
			{
				if(bPA) MemUtil.ZeroByteArray(pbA);
				if(bPB && (pbB != null)) MemUtil.ZeroByteArray(pbB);
			}

			return bEq;
		}

		public ProtectedString Insert(int iStart, string strInsert)
		{
			if(iStart < 0) throw new ArgumentOutOfRangeException("iStart");
			if(strInsert == null) throw new ArgumentNullException("strInsert");
			if(strInsert.Length == 0) return this;

			if(!m_bIsProtected)
				return new ProtectedString(false, ReadString().Insert(
					iStart, strInsert));

			return Insert(iStart, strInsert.ToCharArray(), 0, strInsert.Length);
		}

		internal ProtectedString Insert(int iStart, char[] vInsert,
			int iInsert, int cchInsert)
		{
			if(iStart < 0) throw new ArgumentOutOfRangeException("iStart");
			if(vInsert == null) throw new ArgumentNullException("vInsert");
			if(iInsert < 0) throw new ArgumentOutOfRangeException("iInsert");
			if(cchInsert == 0) return this;
			if((cchInsert < 0) || (cchInsert > (vInsert.Length - iInsert)))
				throw new ArgumentOutOfRangeException("cchInsert");

			if(!m_bIsProtected)
				return new ProtectedString(false, ReadString().Insert(
					iStart, new string(vInsert, iInsert, cchInsert)));

			UTF8Encoding utf8 = StrUtil.Utf8;
			char[] v = ReadChars(), vNew = null;
			byte[] pbNew = null;
			ProtectedString ps;

			try
			{
				if(iStart > v.Length)
					throw new ArgumentOutOfRangeException("iStart");

				vNew = new char[v.Length + cchInsert];
				Array.Copy(v, 0, vNew, 0, iStart);
				Array.Copy(vInsert, iInsert, vNew, iStart, cchInsert);
				Array.Copy(v, iStart, vNew, iStart + cchInsert, v.Length - iStart);

				pbNew = utf8.GetBytes(vNew);
				ps = new ProtectedString(true, pbNew);

				Debug.Assert(utf8.GetString(pbNew, 0, pbNew.Length) ==
					ReadString().Insert(iStart, new string(vInsert, iInsert, cchInsert)));
			}
			finally
			{
				MemUtil.ZeroArray<char>(v);
				if(vNew != null) MemUtil.ZeroArray<char>(vNew);
				if(pbNew != null) MemUtil.ZeroByteArray(pbNew);
			}

			return ps;
		}

		public ProtectedString Remove(int iStart, int nCount)
		{
			if(iStart < 0) throw new ArgumentOutOfRangeException("iStart");
			if(nCount < 0) throw new ArgumentOutOfRangeException("nCount");
			if(nCount == 0) return this;

			if(!m_bIsProtected)
				return new ProtectedString(false, ReadString().Remove(
					iStart, nCount));

			UTF8Encoding utf8 = StrUtil.Utf8;
			char[] v = ReadChars(), vNew = null;
			byte[] pbNew = null;
			ProtectedString ps;

			try
			{
				if((iStart + nCount) > v.Length)
					throw new ArgumentException("(iStart + nCount) > v.Length");

				vNew = new char[v.Length - nCount];
				Array.Copy(v, 0, vNew, 0, iStart);
				Array.Copy(v, iStart + nCount, vNew, iStart, v.Length -
					(iStart + nCount));

				pbNew = utf8.GetBytes(vNew);
				ps = new ProtectedString(true, pbNew);

				Debug.Assert(utf8.GetString(pbNew, 0, pbNew.Length) ==
					ReadString().Remove(iStart, nCount));
			}
			finally
			{
				MemUtil.ZeroArray<char>(v);
				if(vNew != null) MemUtil.ZeroArray<char>(vNew);
				if(pbNew != null) MemUtil.ZeroByteArray(pbNew);
			}

			return ps;
		}

		public static ProtectedString operator +(ProtectedString a, ProtectedString b)
		{
			if(a == null) throw new ArgumentNullException("a");
			if(b == null) throw new ArgumentNullException("b");

			if(b.IsEmpty) return a.WithProtection(a.IsProtected || b.IsProtected);
			if(a.IsEmpty) return b.WithProtection(a.IsProtected || b.IsProtected);
			if(!a.IsProtected && !b.IsProtected)
				return new ProtectedString(false, a.ReadString() + b.ReadString());

			char[] vA = a.ReadChars(), vB = null, vNew = null;
			byte[] pbNew = null;
			ProtectedString ps;

			try
			{
				vB = b.ReadChars();
				vNew = MemUtil.Concat(vA, vB);
				pbNew = StrUtil.Utf8.GetBytes(vNew);
				ps = new ProtectedString(true, pbNew);
			}
			finally
			{
				MemUtil.ZeroArray<char>(vA);
				if(vB != null) MemUtil.ZeroArray<char>(vB);
				if(vNew != null) MemUtil.ZeroArray<char>(vNew);
				if(pbNew != null) MemUtil.ZeroByteArray(pbNew);
			}

			return ps;
		}

		public static ProtectedString operator +(ProtectedString a, string b)
		{
			ProtectedString psB = new ProtectedString(false, b);
			return (a + psB);
		}

		public ProtectedString Trim()
		{
			if(!m_bIsProtected)
			{
				string str = ReadString();
				string strT = str.Trim();
				if(strT.Length == 0) return ProtectedString.Empty;
				if(strT.Length == str.Length) { Debug.Assert(strT == str); return this; }
				return new ProtectedString(false, strT);
			}

			char[] v = ReadChars();
			try
			{
				int iR = v.Length - 1;
				while(iR >= 0)
				{
					if(!char.IsWhiteSpace(v[iR])) break;
					--iR;
				}
				if(iR < 0) return ProtectedString.EmptyEx;

				int iL = 0;
				while(true)
				{
					if(!char.IsWhiteSpace(v[iL])) break;
					++iL;
				}

				if((iL == 0) && (iR == (v.Length - 1))) return this;

				byte[] pb = StrUtil.Utf8.GetBytes(v, iL, iR - iL + 1);
				try { return new ProtectedString(true, pb); }
				finally { MemUtil.ZeroByteArray(pb); }
			}
			finally { MemUtil.ZeroArray<char>(v); }
		}
	}
}
