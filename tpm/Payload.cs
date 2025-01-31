/*
    Payload.cs source code for PowerPass call wrapping
    Copyright 2023-2025 by ShwaTech LLC
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

using System;
using System.Management.Automation;
using System.Text;

namespace PowerPass {
    public class TpmResult {
        public string Payload;
        public int ResultCode;
        public string Message;

        public TpmResult( string[] data ) {
            if( data != null ) {
                switch( data.Length ) {
                    case 0:
                        Payload = String.Empty;
                        ResultCode = -2;
                        Message = "data length 0, expected 2";
                        break;
                    case 1:
                        Payload = data[0];
                        ResultCode = -1;
                        Message = "data length 1, expected 2";
                        break;
                    case 2:
                        Payload = String.Empty;
                        ResultCode = GetResultCode( data[0] );
                        Message = data[1];
                        break;
                    default:
                        var sb = new StringBuilder();
                        for( int i = 0; i < data.Length; i++ ) {
                            if( i == (data.Length - 1) ) {
                                Message = data[i];
                            }
                            else if( i == (data.Length -2 ) ) {
                                ResultCode = GetResultCode( data[i] );
                            }
                            else {
                                sb.Append( data[i] );
                            }
                        }
                        Payload = sb.ToString();
                        break;
                }
            } else {
                Payload = String.Empty;
                ResultCode = -3;
                Message = "data is null";
            }
        }

        private static int GetResultCode( string line ) {
            if( !String.IsNullOrEmpty( line ) ) {
                var splits = line.Split( ":" );
                if( splits.Length == 2 ) {
                    return Convert.ToInt32( splits[1] );
                } else {
                    return -5;
                }
            } else {
                return -4;
            }
        }
    }
}