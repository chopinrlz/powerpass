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