# PowerPass common functions
# Copyright 2023 by The Daltas Group LLC.
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: New-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function New-PowerPassSecret {
    <#
        .SYNOPSIS
        Creates a new PowerPass secret with the standard properties and default values.
    #>
    $nps = [PSCustomObject]@{
        Title = "Default"
        UserName = "PowerPass"
        Password = "PowerPass"
        URL = "https://github.com/chopinrlz/powerpass"
        Notes = "This is the default secret for the PowerPass locker."
        Expires = [DateTime]::MaxValue
        Created = (Get-Date).ToUniversalTime()
        Modified = (Get-Date).ToUniversalTime()
        # Marked For Deletion: flag used by Remove-PowerPassSecret
        Mfd = $false
    }
    Write-Output $nps
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: New-PowerPassAttachment
# ------------------------------------------------------------------------------------------------------------- #

function New-PowerPassAttachment {
    <#
        .SYNOPSIS
        Creates a new PowerPass attachment with the standard properties and default values.
    #>
    $npa = [PSCustomObject]@{
        FileName = "PowerPass.txt"
        Data = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("This is the default text file attachment."))
        Created = [DateTime]::Now.ToUniversalTime()
        Modified = [DateTime]::Now.ToUniversalTime()
    }
    Write-Output $npa
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: New-PowerPassAttachment
# ------------------------------------------------------------------------------------------------------------- #

function New-PowerPassLocker {
    <#
        .SYNOPSIS
        Creates a new PowerPass locker with the standard properties initialized with default values
        or empty values depending on the -Populated parameter.
        .PARAMETER Populated
        Optional switch. When specified, adds a default secret and attachment to the new locker.
    #>
    param(
        [switch]
        $Populated
    )
    $locker = [PSCustomObject]@{
        Created = (Get-Date).ToUniversalTime()
        Modified = (Get-Date).ToUniversalTime()
        Secrets = @()
        Attachments = @()
    }
    if( $Populated ) {
        $locker.Attachments += (New-PowerPassAttachment)
        $locker.Secrets += (New-PowerPassSecret)
    }
    Write-Output $locker
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Set-PowerPassSecureString
# ------------------------------------------------------------------------------------------------------------- #

function Set-PowerPassSecureString {
    <#
        .SYNOPSIS
        Converts a PowerPass secret's password into a SecureString and writes the secret to the pipeline.
        .PARAMETER Secret
        The PowerPass secret. This will be output to the pipeline once the password is converted.
        .INPUTS
        This cmdlet takes PowerPass secrets as input.
        .OUTPUTS
        This cmdlet writes the PowerPass secret to the pipeline after converting the password to a SecureString.
    #>
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline,Position=0)]
        $Secret
    )
    begin {
        # Start work on collection of secrets
    } process {
        if( $Secret.Password ) {
            $Secret.Password = ConvertTo-SecureString -String ($Secret.Password) -AsPlainText -Force
        }
        Write-Output $Secret
    } end {
        # Complete work on collection of secrets
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Get-PowerPassLockerBytes
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassLockerBytes {
    <#
        .SYNOPSIS
        Serializes a PowerPass locker into a JSON UTF-8 encoded byte array.
    #>
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [PSCustomObject]
        $Locker
    )
    $json = ConvertTo-Json -InputObject $Locker
    $data = [System.Text.Encoding]::UTF8.GetBytes($json)
    Write-Output $data
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Test-PowerPassAnswer
# ------------------------------------------------------------------------------------------------------------- #

function Test-PowerPassAnswer {
    <#
        .SYNOPSIS
        Tests an answer prompt from the user for a yes.
        .PARAMETER Answer
        The text reply from the user on the console.
        .INPUTS
        This cmdlet takes a string for input.
        .OUTPUTS
        This cmdlet outputs $true only if the string equals 'y' or 'Y', otherwise $false.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $Answer
    )
    if( $Answer ) {
        if( ($Answer -eq 'y') -or ($Answer -eq 'Y') ) {
            Write-Output $true
        } else {
            Write-Output $false
        }
    } else {
        Write-Output $false
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: New-PowerPassRandomPassword
# ------------------------------------------------------------------------------------------------------------- #

function New-PowerPassRandomPassword {
    <#
        .SYNOPSIS
        Generates a random password from all available standard US 101-key keyboard characters.
        .PARAMETER Length
        The length of the password to generate. Can be between 1 and 65536 characters long. Defaults to 24.
        .OUTPUTS
        Outputs a random string of typable characters to the pipeline which can be used as a password.
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1,65536)]
        [int]
        $Length = 24
    )
    $bytes = [System.Byte[]]::CreateInstance( [System.Byte], $Length )
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes( $bytes )
    $bytes = $bytes | % { ( $_ % ( 126 - 33 ) ) + 33 }
    [System.Text.Encoding]::ASCII.GetString( $bytes )
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Get-PowerPassCredential
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassCredential {
    <#
        .SYNOPSIS
        Converts a PowerPass secret into a PSCredential.
        .PARAMETER Secret
        The PowerPass secret.
    #>
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [PSCustomObject]
        $Secret
    )
    $x = @(($Secret.UserName), (ConvertTo-SecureString -String ($Secret.Password) -AsPlainText -Force))
    New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $x
}