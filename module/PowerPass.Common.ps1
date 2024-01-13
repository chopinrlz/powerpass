# PowerPass common functions
# Copyright 2023-2024 by The Daltas Group LLC.
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
        # Marked For Deletion: flag used by Remove-PowerPassAttachment
        Mfd = $false
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline,Position=0)]
        $Secret
    )
    # Process blocks are required for pipeline to correctly process reads on multiple items
    begin {
        # Do not remove
    } process {
        if( $Secret.Password ) {
            $Secret.Password = ConvertTo-SecureString -String ($Secret.Password) -AsPlainText -Force
        }
        Write-Output $Secret
    } end {
        # Do not remove
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [PSCustomObject]
        $Secret
    )
    # Process blocks are required for PowerPass to pipeline reads of multiple items
    begin {
        # Do not remove
    } process {
        $x = @(($Secret.UserName), (ConvertTo-SecureString -String ($Secret.Password) -AsPlainText -Force))
        $c = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $x
        Write-Output $c
    } end {
        # Do not remove
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Get-PowerPassMaskedPassword
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassMaskedPassword {
    <#
        .SYNOPSIS
        Prompts the user to enter a password on the console while masking the entry.
        .PARAMETER Prompt
        Optional. The prompt to echo to the user.
    #>
    param(
        [string]
        $Prompt = "Enter a password"
    )
    $x = ""
    if( $PSVersionTable.PSVersion.Major -eq 5 ) {
        $secString = Read-Host "$Prompt" -AsSecureString
        $bString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $secString )
        $x = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto( $bString )
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR( $bString )
    } else {
        $x = Read-Host -Prompt "$Prompt" -MaskInput
    }
    Write-Output $x
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Get-PowerPassAttachments
# ------------------------------------------------------------------------------------------------------------- #

function Get-PowerPassAttachments {
    <#
        .SYNOPSIS
        Exports all the attachments to a list so you can search for attachments and see what attachments are
        in your locker without exposing the file data.
        .OUTPUTS
        Outputs each attachment from your locker including the FileName, Created date, and Modified date.
    #>
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Could not create or fetch your locker"
    }
    $locker.Attachments | Select-Object -Property FileName,Created,Modified
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Read-PowerPassAttachment
# ------------------------------------------------------------------------------------------------------------- #

function Read-PowerPassAttachment {
    <#
        .SYNOPSIS
        Reads an attachment from your locker.
        .PARAMETER FileName
        The filename of the attachment to fetch.
        .PARAMETER Raw
        An optional parameter that, when specified, will return the entire PSCustomObject for the attachment.
        Cannot be combined with Encoding.
        .PARAMETER AsText
        An optional parameter that, when specified, will return the attachment data as a Unicode string. Cannot
        be combined with Raw.
        .PARAMETER Encoding
        If -AsText is specified, you can optionally specify a specific encoding, otherwise the default encoding
        Unicode is used since Unicode is the default encoding used when writing text attachments into your locker.
        .OUTPUTS
        Outputs the attachment data in byte[] format, or the PSCustomObject if -Raw was specified, or a
        string if -AsText was specified, or $null if no file was found matching the specified filename.
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    param(
        [Parameter(ParameterSetName="Default",Mandatory,ValueFromPipeline,Position=0)]
        [Parameter(ParameterSetName="Raw",Mandatory,ValueFromPipeline,Position=0)]
        [Parameter(ParameterSetName="AsText",Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $FileName,
        [Parameter(ParameterSetName="Raw")]
        [switch]
        $Raw,
        [Parameter(ParameterSetName="AsText")]
        [switch]
        $AsText,
        [Parameter(ParameterSetName="AsText")]
        [ValidateSet("Ascii","Utf8","Unicode")]
        [string]
        $Encoding
    )
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Could not create or fetch your locker"
    }
    if( $locker.Attachments ) {
        if( $FileName ) {
            $attachment = $locker.Attachments | Where-Object { $_.FileName -eq $FileName }
            if( $attachment ) {
                if( $Raw ) {
                    Write-Output $attachment
                } elseif( $AsText ) {
                    $bytes = [System.Convert]::FromBase64String($attachment.Data)
                    switch( $Encoding ) {
                        "Ascii" {
                            Write-Output ([System.Text.Encoding]::ASCII).GetString($bytes)
                        }
                        "Utf8" {
                            Write-Output ([System.Text.Encoding]::UTF8).GetString($bytes)
                        }
                        "Unicode" {
                            Write-Output ([System.Text.Encoding]::Unicode).GetString($bytes)
                        }
                        default {
                            Write-Output ([System.Text.Encoding]::Unicode).GetString($bytes)
                        }
                    }
                } else {
                    Write-Output ([System.Convert]::FromBase64String($attachment.Data))
                }
            } else {
                Write-Output $null
            }
        } else {
            Write-Output $null
        }
    } else {
        Write-Output $null
    }
}

# ------------------------------------------------------------------------------------------------------------- #
# FUNCTION: Read-PowerPassSecret
# ------------------------------------------------------------------------------------------------------------- #

function Read-PowerPassSecret {
    <#
        .SYNOPSIS
        Reads secrets from your PowerPass locker.
        .PARAMETER Match
        An optional filter. If specified, only secrets whose Title matches this filter are output to the pipeline.
        Cannot be combined with Title as Title will be ignored if Match is specified.
        .PARAMETER Title
        An optional exact match filter. If specified, only the secret which exactly matches the Title will be
        output to the pipeline. Do not combine with Match as Title will be ignored if Match is specified.
        .PARAMETER PlainTextPasswords
        An optional switch which instructs PowerPass to output the passwords in plain-text. By default, all
        passwords are output as SecureString objects. You cannot combine this with AsCredential.
        .PARAMETER AsCredential
        An optional switch which instructs PowerPass to output the secrets as PSCredential objects. You cannot
        combine this with PlainTextPasswords.
        .OUTPUTS
        This cmdlet outputs PowerPass secrets from your locker to the pipeline. Each secret is a PSCustomObject
        with these properties:
        1. Title     - the name, or title, of the secret, this value is unique to the locker
        2. UserName  - the username field string for the secret
        3. Password  - the password field for the secret, by default a SecureString
        4. URL       - the URL string for the secret
        5. Notes     - the notes string for the secret
        6. Expires   - the expiration date for the secret, by default December 31, 9999
        7. Created   - the date and time the secret was created in the locker
        8. Modified  - the date and time the secret was last modified
        .NOTES
        When you use PowerPass for the first time, PowerPass creates a default secret in your locker with the
        Title "Default" with all fields populated as an example of the data structure stored in the locker.
        You can delete or change this secret by using Write-PowerPassSecret or Delete-PowerPassSecret and specifying
        the Title of "Default".
    #>
    param(
        [Parameter(ValueFromPipeline,Position=0)]
        [string]
        $Match,
        [string]
        $Title,
        [switch]
        $PlainTextPasswords,
        [switch]
        $AsCredential
    )
    $locker = Get-PowerPassLocker
    if( -not $locker ) {
        throw "Could not create or fetch your locker"
    }
    if( $locker.Secrets ) {
        if( $Match ) {
            $secrets = $locker.Secrets | Where-Object { $_.Title -like $Match }
            if( $PlainTextPasswords ) {
                Write-Output $secrets
            } else {
                if( $AsCredential ) {
                    $secrets | Get-PowerPassCredential
                } else {
                    $secrets | Set-PowerPassSecureString
                }
            }
        } elseif( $Title ) {
            foreach( $secret in $locker.Secrets ) {
                if( $secret.Title -eq $Title ) {
                    if( $PlainTextPasswords ) {
                        Write-Output $secret
                    } else {
                        if( $AsCredential ) {
                            $secret | Get-PowerPassCredential
                        } else {
                            $secret | Set-PowerPassSecureString
                        }
                    }
                }
            }
        } else {
            if( $PlainTextPasswords ) {
                Write-Output $locker.Secrets
            } else {
                if( $AsCredential ) {
                    $locker.Secrets | Get-PowerPassCredential
                } else {
                    $locker.Secrets | Set-PowerPassSecureString
                }
            }
        }
    } else {
        Write-Output $null
    }
}