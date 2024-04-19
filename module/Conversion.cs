/*
    Conversion.cs source code for CLR call wrapping in Cmdlets to avoid AMSI invocation
    Copyright 2023-2024 by ShwaTech LLC
    This software is provided AS IS WITHOUT WARRANTEE.
    You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.
*/

using System;
using System.Management.Automation;

[Cmdlet("ConvertFrom", "Base64String")]
public class ConvertFromBase64String : PSCmdlet {
    [Parameter(Mandatory=true,ValueFromPipeline=true)]
    public String InputString;

    protected override void ProcessRecord() {
        WriteObject( System.Convert.FromBase64String( InputString ) );
    }
}

[Cmdlet("ConvertTo", "Base64String")]
public class ConvertToBase64String : PSCmdlet {
    [Parameter(Mandatory=true,ValueFromPipeline=true)]
    public byte[] InputObject;

    protected override void ProcessRecord() {
        WriteObject( System.Convert.ToBase64String( InputObject ) );
    }
}

[Cmdlet("ConvertTo", "Utf8ByteArray")]
public class ConvertToUtf8ByteArray : PSCmdlet {
    [Parameter(Mandatory=true,ValueFromPipeline=true)]
    public String InputString;

    protected override void ProcessRecord() {
        WriteObject( System.Text.Encoding.UTF8.GetBytes( InputString ) );
    }
}

[Cmdlet("ConvertTo", "Utf8String")]
public class ConvertToUtf8String : PSCmdlet {
    [Parameter(Mandatory=true,ValueFromPipeline=true)]
    public byte[] InputObject;

    protected override void ProcessRecord() {
        WriteObject( System.Text.Encoding.UTF8.GetString( InputObject ) );
    }
}

[Cmdlet("Write", "AllFileBytes")]
public class WriteAllFileBytes : PSCmdlet {
    [Parameter(Mandatory=true,ValueFromPipeline=true)]
    public byte[] InputObject;

    [Parameter(Mandatory=true)]
    public string LiteralPath;

    protected override void ProcessRecord() {
        System.IO.File.WriteAllBytes( LiteralPath, InputObject );
    }
}

[Cmdlet("Write", "OutputByProxy")]
public class WriteOutputByProxy : PSCmdlet {
    [Parameter(Mandatory=true,ValueFromPipeline=true)]
    public object InputObject;

    protected override void ProcessRecord() {
        WriteObject( InputObject );
    }
}