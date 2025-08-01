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
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Text;

using KeePassLib.Interfaces;

namespace KeePassLib.Utility
{
	/// <summary>
	/// Contains various static time structure manipulation and conversion
	/// routines.
	/// </summary>
	public static class TimeUtil
	{
		/// <summary>
		/// Length of a compressed <c>PW_TIME</c> structure in bytes.
		/// </summary>
		public const int PwTimeLength = 7;

		public static readonly DateTime SafeMinValueUtc = new DateTime(
			DateTime.MinValue.Ticks + TimeSpan.TicksPerDay, DateTimeKind.Utc);
		public static readonly DateTime SafeMaxValueUtc = new DateTime(
			DateTime.MaxValue.Ticks - TimeSpan.TicksPerDay, DateTimeKind.Utc);

#if !KeePassLibSD
		private static string m_strDtfStd = null;
		private static string m_strDtfDate = null;
#endif

		// private static long m_lTicks2PowLess1s = 0;

		private static DateTime? m_odtUnixRoot = null;
		public static DateTime UnixRoot
		{
			get
			{
				if(m_odtUnixRoot.HasValue) return m_odtUnixRoot.Value;

				DateTime dtRoot = new DateTime(1970, 1, 1, 0, 0, 0, 0,
					DateTimeKind.Utc);

				m_odtUnixRoot = dtRoot;
				return dtRoot;
			}
		}

		/// <summary>
		/// Convert a <c>DateTime</c> object to a displayable string.
		/// </summary>
		/// <param name="dt"><c>DateTime</c> object to convert to a string.</param>
		/// <returns>String representing the specified <c>DateTime</c> object.</returns>
		public static string ToDisplayString(DateTime dt)
		{
			return ToLocal(dt, true).ToString();
		}

		public static string ToDisplayStringDateOnly(DateTime dt)
		{
			return ToLocal(dt, true).ToString("d");
		}

		public static DateTime FromDisplayString(string strDisplay)
		{
			DateTime dt;
			if(FromDisplayStringEx(strDisplay, out dt)) return dt;
			return DateTime.Now;
		}

		public static bool FromDisplayStringEx(string strDisplay, out DateTime dt)
		{
#if KeePassLibSD
			try { dt = ToLocal(DateTime.Parse(strDisplay), true); return true; }
			catch(Exception) { }
#else
			if(DateTime.TryParse(strDisplay, out dt))
			{
				dt = ToLocal(dt, true);
				return true;
			}

			// For some custom formats specified using the Control Panel,
			// DateTime.ToString returns the correct string, but
			// DateTime.TryParse fails (e.g. for "//dd/MMM/yyyy");
			// https://sourceforge.net/p/keepass/discussion/329221/thread/3a225b29/?limit=25&page=1#c6ae
			if((m_strDtfStd == null) || (m_strDtfDate == null))
			{
				DateTime dtUni = new DateTime(2111, 3, 4, 5, 6, 7, DateTimeKind.Local);
				m_strDtfStd = DeriveCustomFormat(ToDisplayString(dtUni), dtUni);
				m_strDtfDate = DeriveCustomFormat(ToDisplayStringDateOnly(dtUni), dtUni);
			}
			const DateTimeStyles dts = DateTimeStyles.AllowWhiteSpaces;
			if(DateTime.TryParseExact(strDisplay, m_strDtfStd, null, dts, out dt))
			{
				dt = ToLocal(dt, true);
				return true;
			}
			if(DateTime.TryParseExact(strDisplay, m_strDtfDate, null, dts, out dt))
			{
				dt = ToLocal(dt, true);
				return true;
			}
#endif

			Debug.Assert(false);
			return false;
		}

#if !KeePassLibSD
		private static string DeriveCustomFormat(string strDT, DateTime dt)
		{
			string[] vPlh = new string[] {
				// Names, sorted by length
				"MMMM", "dddd",
				"MMM", "ddd",
				"gg", "g",

				// Numbers, the ones with prefix '0' first
				"yyyy", "yyy", "yy", "y",
				"MM", "M",
				"dd", "d",
				"HH", "hh", "H", "h",
				"mm", "m",
				"ss", "s",

				"tt", "t"
			};

			List<string> lValues = new List<string>();
			foreach(string strPlh in vPlh)
			{
				string strEval = strPlh;
				if(strEval.Length == 1) strEval = @"%" + strPlh; // Make custom

				lValues.Add(dt.ToString(strEval));
			}

			StringBuilder sbAll = new StringBuilder();
			sbAll.Append("dfFghHKmMstyz:/\"\'\\%");
			sbAll.Append(strDT);
			foreach(string strVEnum in lValues) { sbAll.Append(strVEnum); }

			List<char> lCodes = new List<char>();
			for(int i = 0; i < vPlh.Length; ++i)
			{
				char ch = StrUtil.GetUnusedChar(sbAll.ToString());
				lCodes.Add(ch);
				sbAll.Append(ch);
			}

			string str = strDT;
			for(int i = 0; i < vPlh.Length; ++i)
			{
				string strValue = lValues[i];
				if(string.IsNullOrEmpty(strValue)) continue;

				str = str.Replace(strValue, new string(lCodes[i], 1));
			}

			StringBuilder sbFmt = new StringBuilder();
			bool bInLiteral = false;
			foreach(char ch in str)
			{
				int iCode = lCodes.IndexOf(ch);

				// The escape character doesn't work correctly (e.g.
				// "dd\\.MM\\.yyyy\\ HH\\:mm\\:ss" doesn't work, but
				// "dd'.'MM'.'yyyy' 'HH':'mm':'ss" does); use '' instead

				// if(iCode >= 0) sbFmt.Append(vPlh[iCode]);
				// else // Literal
				// {
				//	sbFmt.Append('\\');
				//	sbFmt.Append(ch);
				// }

				if(iCode >= 0)
				{
					if(bInLiteral) { sbFmt.Append('\''); bInLiteral = false; }
					sbFmt.Append(vPlh[iCode]);
				}
				else // Literal
				{
					if(!bInLiteral) { sbFmt.Append('\''); bInLiteral = true; }
					sbFmt.Append(ch);
				}
			}
			if(bInLiteral) sbFmt.Append('\'');

			return sbFmt.ToString();
		}
#endif

		public static string SerializeUtc(DateTime dt)
		{
			Debug.Assert(dt.Kind != DateTimeKind.Unspecified);

			string str = ToUtc(dt, false).ToString("s");
			if(!str.EndsWith("Z")) str += "Z";
			return str;
		}

		public static bool TryDeserializeUtc(string str, out DateTime dt)
		{
			if(str == null) throw new ArgumentNullException("str");

			if(str.EndsWith("Z")) str = str.Substring(0, str.Length - 1);

			bool bResult = StrUtil.TryParseDateTime(str, out dt);
			if(bResult) dt = ToUtc(dt, true);
			return bResult;
		}

		public static double SerializeUnix(DateTime dt)
		{
			return (ToUtc(dt, false) - TimeUtil.UnixRoot).TotalSeconds;
		}

		public static DateTime ConvertUnixTime(double dtUnix)
		{
			try { return TimeUtil.UnixRoot.AddSeconds(dtUnix); }
			catch(Exception) { Debug.Assert(false); }

			return DateTime.UtcNow;
		}

#if !KeePassLibSD
		[Obsolete]
		public static DateTime? ParseUSTextDate(string strDate)
		{
			return ParseUSTextDate(strDate, DateTimeKind.Unspecified);
		}

		private static string[] m_vUSMonths = null;
		/// <summary>
		/// Parse a US textual date string, like e.g. "January 02, 2012".
		/// </summary>
		public static DateTime? ParseUSTextDate(string strDate, DateTimeKind k)
		{
			if(strDate == null) { Debug.Assert(false); return null; }

			if(m_vUSMonths == null)
				m_vUSMonths = new string[] { "January", "February", "March",
					"April", "May", "June", "July", "August", "September",
					"October", "November", "December" };

			string str = strDate.Trim();
			for(int i = 0; i < m_vUSMonths.Length; ++i)
			{
				if(str.StartsWith(m_vUSMonths[i], StrUtil.CaseIgnoreCmp))
				{
					str = str.Substring(m_vUSMonths[i].Length);
					string[] v = str.Split(new char[] { ',', ';' });
					if((v == null) || (v.Length != 2)) return null;

					string strDay = v[0].Trim().TrimStart('0');
					int iDay, iYear;
					if(int.TryParse(strDay, out iDay) &&
						int.TryParse(v[1].Trim(), out iYear))
						return new DateTime(iYear, i + 1, iDay, 0, 0, 0, k);
					else { Debug.Assert(false); return null; }
				}
			}

			return null;
		}
#endif

		private static readonly DateTime m_dtInvMin =
			new DateTime(2999, 12, 27, 23, 59, 59, DateTimeKind.Utc);
		private static readonly DateTime m_dtInvMax =
			new DateTime(2999, 12, 29, 23, 59, 59, DateTimeKind.Utc);
		public static int Compare(DateTime dtA, DateTime dtB, bool bUnkIsPast)
		{
			Debug.Assert(dtA.Kind == dtB.Kind);

			if(bUnkIsPast)
			{
				// 2999-12-28 23:59:59 in KeePass 1.x means 'unknown';
				// expect time zone corruption (twice)
				// bool bInvA = ((dtA.Year == 2999) && (dtA.Month == 12) &&
				//	(dtA.Day >= 27) && (dtA.Day <= 29) && (dtA.Minute == 59) &&
				//	(dtA.Second == 59));
				// bool bInvB = ((dtB.Year == 2999) && (dtB.Month == 12) &&
				//	(dtB.Day >= 27) && (dtB.Day <= 29) && (dtB.Minute == 59) &&
				//	(dtB.Second == 59));
				// Faster due to internal implementation of DateTime:
				bool bInvA = ((dtA >= m_dtInvMin) && (dtA <= m_dtInvMax) &&
					(dtA.Minute == 59) && (dtA.Second == 59));
				bool bInvB = ((dtB >= m_dtInvMin) && (dtB <= m_dtInvMax) &&
					(dtB.Minute == 59) && (dtB.Second == 59));

				if(bInvA) return (bInvB ? 0 : -1);
				if(bInvB) return 1;
			}

			return dtA.CompareTo(dtB);
		}

		internal static int CompareLastMod(ITimeLogger tlA, ITimeLogger tlB,
			bool bUnkIsPast)
		{
			if(tlA == null) { Debug.Assert(false); return ((tlB == null) ? 0 : -1); }
			if(tlB == null) { Debug.Assert(false); return 1; }

			return Compare(tlA.LastModificationTime, tlB.LastModificationTime,
				bUnkIsPast);
		}

		public static DateTime ToUtc(DateTime dt, bool bUnspecifiedIsUtc)
		{
			DateTimeKind k = dt.Kind;
			if(k == DateTimeKind.Utc) return dt;
			if(k == DateTimeKind.Local) return dt.ToUniversalTime();

			Debug.Assert(k == DateTimeKind.Unspecified);
			if(bUnspecifiedIsUtc)
				return new DateTime(dt.Ticks, DateTimeKind.Utc);
			return dt.ToUniversalTime(); // Unspecified = local
		}

		public static DateTime ToLocal(DateTime dt, bool bUnspecifiedIsLocal)
		{
			DateTimeKind k = dt.Kind;
			if(k == DateTimeKind.Local) return dt;
			if(k == DateTimeKind.Utc) return dt.ToLocalTime();

			Debug.Assert(k == DateTimeKind.Unspecified);
			if(bUnspecifiedIsLocal)
				return new DateTime(dt.Ticks, DateTimeKind.Local);
			return dt.ToLocalTime(); // Unspecified = UTC
		}

		/* internal static DateTime RoundToMultOf2PowLess1s(DateTime dt)
		{
			long l2Pow = m_lTicks2PowLess1s;
			if(l2Pow == 0)
			{
				l2Pow = 1;
				while(true)
				{
					l2Pow <<= 1;
					if(l2Pow >= TimeSpan.TicksPerSecond) break;
				}
				l2Pow >>= 1;
				m_lTicks2PowLess1s = l2Pow;

				Debug.Assert(TimeSpan.TicksPerSecond == 10000000L); // .NET
				Debug.Assert(l2Pow == (1L << 23)); // .NET
			}

			long l = dt.Ticks;
			if((l % l2Pow) == 0L) return dt;

			// Round down to full second
			l /= TimeSpan.TicksPerSecond;
			l *= TimeSpan.TicksPerSecond;

			// Round up to multiple of l2Pow
			long l2PowM1 = l2Pow - 1L;
			l = (l + l2PowM1) & ~l2PowM1;
			DateTime dtRnd = new DateTime(l, dt.Kind);

			Debug.Assert((dtRnd.Ticks % l2Pow) == 0L);
			Debug.Assert(dtRnd.ToString("u") == dt.ToString("u"));
			return dtRnd;
		} */

		/// <summary>
		/// Check equality of two times with precision 1 s, floor-rounded.
		/// Ticks finer than 1 s are ignored.
		/// </summary>
		internal static bool EqualsFloor(DateTime dtA, DateTime dtB)
		{
			// DateTime.Equals ignores the kind
			Debug.Assert(dtA.Kind == dtB.Kind);

			long sA = dtA.Ticks / TimeSpan.TicksPerSecond;
			long sB = dtB.Ticks / TimeSpan.TicksPerSecond;

			return (sA == sB);
		}
	}
}
