using System;

namespace PowerPass {
	public class CustomObject {
		public string MyValue { get; set; }

		public override string ToString() {
			return MyValue;
		}
	}
}