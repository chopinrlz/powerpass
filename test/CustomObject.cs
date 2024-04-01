/*
    CustomObject.cs source code for testing object storage
    Copyright 2023-2024 by ShwaTech LLC
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

using System;

namespace PowerPass {
	public class CustomObject {
		public string MyValue { get; set; }

		public override string ToString() {
			return MyValue;
		}
	}
}