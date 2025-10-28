# PowerPass common functions
# Copyright 2023-2025 by ShwaTech LLC
# This software is provided AS IS WITHOUT WARRANTEE.
# You may copy, modify or distribute this software under the terms of the GNU Public License 2.0.

function Get-PowerPass {
    <#
        .SYNOPSIS
        Gets all the information about this PowerPass deployment.
    #>
    $PowerPass
}

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

function New-PowerPassAttachment {
    <#
        .SYNOPSIS
        Creates a new PowerPass attachment with the standard properties and default values.
    #>
    $npa = [PSCustomObject]@{
        FileName = "PowerPass.txt"
        Data = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("This is the default text file attachment."))
        Created = [DateTime]::Now.ToUniversalTime()
        Modified = [DateTime]::Now.ToUniversalTime()
        # Marked For Deletion: flag used by Remove-PowerPassAttachment
        Mfd = $false
        # GZip Compression flag - added v2.1.0
        GZip = $false
    }
    Write-Output $npa
}

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
        # Added a Revision flag in PowerPass v3 for OTP support
        Revision = 3
    }
    if( $Populated ) {
        $locker.Attachments += (New-PowerPassAttachment)
        $locker.Secrets += (New-PowerPassSecret)
    }
    Write-Output $locker
}

function Get-PowerPassIsNewer {
    <#
        .SYNOPSIS
        Compares secrets or attachments to determine if theirs is newer than ours.
        .PARAMETER Ours
        Our local secret or attachment.
        .PARAMETER Theirs
        Their imported secret or attachment.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $Ours,
        [Parameter(Mandatory)]
        [PSCustomObject]
        $Theirs
    )
    if( $Ours ) {
        if( $Theirs ) {
            Write-Output (($Theirs.Created -gt $Ours.Created) -or ($Theirs.Modified -gt $Ours.Modified))
        } else {
            Write-Output $false
        }
    } else {
        Write-Output $true
    }
}

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
        [PSCustomObject]
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

function Get-PowerPassLockerBytes {
    <#
        .SYNOPSIS
        Serializes a PowerPass locker into a JSON UTF-8 encoded byte array.
        .PARAMETER Locker
        The Locker object with secrets and attachments.
        .PARAMETER Data
        A reference to a byte[] where the Locker bytes will be stored.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $Locker,
        [Parameter(Mandatory)]
        [ref]
        $Data
    )
    $json = ConvertTo-Json -InputObject $Locker
    $Data.Value = ConvertTo-Utf8ByteArray -InputString $json
}

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

function New-PowerPassRandomPassword {
    <#
        .SYNOPSIS
        Generates a random ASCII password from all available letters, numbers, and special characters
        typable on a standard US 101-key keyboard.
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
    $bytes = $bytes | ForEach-Object { ( $_ % 93 ) + 33 }
    [System.Text.Encoding]::ASCII.GetString( $bytes )
}

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

function Get-PowerPassAttachments {
    <#
        .SYNOPSIS
        Exports all the attachments to a list so you can search for attachments and see what attachments are
        in your locker without exposing the file data.
        .OUTPUTS
        Outputs each attachment from your locker including the FileName, Created date, and Modified date.
    #>
    [PSCustomObject]$locker = $null
    Get-PowerPassLocker -Locker ([ref] $locker)
    if( -not $locker ) {
        throw "Could not create or fetch your locker"
    }
    $locker.Attachments | Select-Object -Property FileName,Created,Modified
}

function Add-PowerPassAttachment {
    <#
        .SYNOPSIS
        Adds files from the file system into your locker.
        .PARAMETER FileInfo
        One or more FileInfo objects collected from Get-ChildItem.
        .PARAMETER FullPath
        If specified, the full file path will be saved as the file name. If the file already exists, it will be
        updated in your locker.
        .PARAMETER GZip
        Enable GZip compression.
        .NOTES
        Rather than using Write-PowerPassAttachment, you can use Add-PowerPassAttachment to add multiple files
        to your locker at once by piping the output of Get-ChildItem to Add-PowerPassAttachment. Each file fetched
        by Get-ChildItem will be added to your locker using either the file name or the full path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        $FileInfo,
        [switch]
        $FullPath,
        [switch]
        $GZip
    )
    begin {
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
        if( -not $locker ) {
            throw "Could not create or fetch your locker"
        }
        $changed = $false
        if( $locker.Attachments.Length -le 0 ) {
            $locker.Attachments = @()
        }
    } process {
        if( $FileInfo -is [System.IO.FileInfo] ) {
            $changed = $true
            [byte[]]$bytes = $null
            if( $GZip ) {
                $bytes = [PowerPass.Compressor]::CompressFromDisk( $FileInfo.FullName )
            } else {
                $bytes = [System.IO.File]::ReadAllBytes( $FileInfo.FullName )
            }
            $fileData = [System.Convert]::ToBase64String( $bytes )
            $fileName = ""
            if( $FullPath ) {
                $fileName = $FileInfo.FullName
            } else {
                $fileName = $FileInfo.Name
            }
            $ex = $locker.Attachments | Where-Object { $_.FileName -eq $fileName }
            if( $ex ) {
                $ex.Data = $fileData
                $ex.Modified = (Get-Date).ToUniversalTime()
                if( -not (Get-Member -InputObject $ex -Name "GZip") ) {
                    Add-Member -InputObject $ex -Name "GZip" -Value $false
                }
                if( $GZip ) {
                    $ex.GZip = $true
                } else {
                    $ex.GZip = $false
                }
            } else {
                $ex = New-PowerPassAttachment
                $ex.FileName = $fileName
                $ex.Data = $fileData
                if( $GZip ) {
                    $ex.GZip = $true
                } else {
                    $ex.GZip = $false
                }
                $locker.Attachments += $ex
            }
        }
    } end {
        if( $changed ) {
            Out-PowerPassLocker -Locker $locker
        }
    }
}

function Read-PowerPassAttachment {
    <#
        .SYNOPSIS
        Reads an attachment from your locker.
        .PARAMETER FileName
        The filename of the attachment to fetch.
        .PARAMETER Raw
        An optional parameter that, when specified, will return the entire PSCustomObject for the attachment.
        Cannot be combined with AsText or Encoding.
        .PARAMETER AsText
        An optional parameter that, when specified, will return the attachment data as a Unicode string. Cannot
        be combined with Raw.
        .PARAMETER Encoding
        If `-AsText` is specified, you can optionally specify a specific encoding, otherwise the default encoding
        Unicode is used since Unicode is the default encoding used when writing text attachments into your locker.
        This parameter can be useful if you stored a text attachment into your locker from a byte array since the
        contents of the file may be ASCII, UTF-8, or Unicode you can specify that with the `-Encoding` parameter.
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
    [PSCustomObject]$locker = $null
    Get-PowerPassLocker -Locker ([ref] $locker)
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
                    [byte[]]$bytes = $null
                    if( $attachment.GZip ) {
                        $comp = ConvertFrom-Base64String -InputString $attachment.Data
                        $bytes = [PowerPass.Compressor]::DecompressBytes( $comp )
                    } else {
                        $bytes = ConvertFrom-Base64String -InputString $attachment.Data
                    }
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
                    $comp = ConvertFrom-Base64String -InputString $attachment.Data
                    # Removed to avoid pushing warnings onto the pipeline since a $null or file data is expected
                    # if( $PSVersionTable.PSVersion.Major -eq 5 ) {
                    #   if( $comp.Length -ge (10 * 1024 * 1024) ) {
                    #     Write-Warning "Windows PowerShell 5.1 has a known issue with large byte arrays"
                    #   }
                    # }
                    if( $attachment.GZip ) {
                        $file = [PowerPass.Compressor]::DecompressBytes( $comp )
                        # Write-Output causes a memory leak and does not complete in Windows PowerShell 5.1 with large byte arrays
                        # This has been replaced with a proxy cmdlet that simply hands the underlying object to the caller
                        Write-OutputByProxy -InputObject $file
                    } else {
                        # Write-Output causes a memory leak and does not complete in Windows PowerShell 5.1 with large byte arrays
                        # This has been replaced with a proxy cmdlet that simply hands the underlying object to the caller
                        Write-OutputByProxy -InputObject $comp
                    }
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

function Write-PowerPassAttachment {
    <#
        .SYNOPSIS
        Writes an attachment into your locker.
        .PARAMETER FileName
        The name of the file to write into your locker. If this file already exists, it will be updated.
        .PARAMETER Path
        Option 1: you may specify the Path to a file on disk.
        .PARAMETER LiteralPath
        Option 2: you may specify the LiteralPath to a file on disk.
        .PARAMETER Data
        Option 3: you may specify the Data for the file in any format, or from the pipeline such as from Get-ChildItem.
        .PARAMETER Text
        Option 4: you may specify the contents of the file as a text string.
        .PARAMETER GZip
        An optional parameter to compress the attachment using GZip before storing it.
        .NOTES
        Data and Text in string format is encoded with Unicode. Data in PSCustomObject format is converted to JSON then
        encoded with Unicode. Byte arrays and FileInfo objects are stored natively. Data in any other formats is converted
        to a string using the build-in .NET ToString function then encoded with Unicode. To fetch text back from your locker
        saved as attachments use the -AsText parameter of Read-PowerPassAttachment to ensure the correct encoding is used.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]
        $FileName,
        [Parameter(ParameterSetName="FromDisk")]
        [string]
        $Path,
        [Parameter(ParameterSetName="FromDiskLiteral")]
        [string]
        $LiteralPath,
        [Parameter(ParameterSetName="FromPipeline",ValueFromPipeline)]
        $Data,
        [Parameter(ParameterSetName="FromString",Position=1)]
        [string]
        $Text,
        [Parameter(ParameterSetName="FromDisk")]
        [Parameter(ParameterSetName="FromDiskLiteral")]
        [Parameter(ParameterSetName="FromPipeline")]
        [switch]
        $GZip
    )
    begin {
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
        if( -not $locker ) {
            throw "Could not create or fetch your locker"
        }
        if( $locker.Attachments.Length -le 0 ) {
            $locker.Attachments = @()
        }
    } process {
        [byte[]]$bytes = $null
        $setGZipFlag = $false
        if( $Path ) {
            $fileInfo = Get-Item -Path $Path
            if( $GZip ) {
                $bytes = [PowerPass.Compressor]::CompressFromDisk( $fileInfo.FullName )
                $setGZipFlag = $true
            } else {
                $bytes = [System.IO.File]::ReadAllBytes( $fileInfo.FullName )
            }
        } elseif( $LiteralPath ) {
            $fileInfo = Get-Item -LiteralPath $LiteralPath
            if( $GZip ) {
                $bytes = [PowerPass.Compressor]::CompressFromDisk( $fileInfo.FullName )
                $setGZipFlag = $true
            } else {
                $bytes = [System.IO.File]::ReadAllBytes( $fileInfo.FullName )
            }
        } elseif( $Data ) {
            $dataType = $Data.GetType().FullName
            switch( $dataType ) {
                "System.Object[]" {
                    # Here we assume what happened is the caller ran Get-Content and it returned a
                    # text file as an array of strings which is the default behavior. We also need
                    # to guess what the file's hard return is since it has been removed from the
                    # data itself by Get-Content.
                    $hardReturn = "`r`n"
                    if( $IsLinux -or $IsMacOS ) {
                        $hardReturn = "`n"
                    }
                    $sb = New-Object "System.Text.StringBuilder"
                    for( $i = 0; $i -lt ($Data.Length - 1); $i++ ) {
                        $null = $sb.Append( $Data[$i].ToString() ).Append( $hardReturn )
                    }
                    # Avoid adding an extra hard return to the end of the data
                    $null = $sb.Append( $Data[-1].ToString() )
                    $bytes = ([System.Text.Encoding]::Unicode).GetBytes( $sb.ToString() )
                }
                "System.Byte[]" {
                    $bytes = $Data
                }
                "System.IO.FileInfo" {
                    if( $GZip ) {
                        $bytes = [PowerPass.Compression]::CompressFromDisk( $Data.FullName )
                        $setGZipFlag = $true
                    } else {
                        $bytes = [System.IO.File]::ReadAllBytes( $Data.FullName )
                    }
                }
                "System.String" {
                    $bytes = ([System.Text.Encoding]::Unicode).GetBytes( $Data )
                }
                "System.Management.Automation.PSCustomObject" {
                    $json = ConvertTo-Json -InputObject $Data -Depth 99
                    $bytes = ([System.Text.Encoding]::Unicode).GetBytes( $json )
                }
                default {
                    $bytes = ([System.Text.Encoding]::Unicode).GetBytes( $Data.ToString() )
                }
            }
        } elseif( $Text ) {
            $bytes = ([System.Text.Encoding]::Unicode).GetBytes( $Text )
        } else {
            throw "Error, no input specified"
        }
        $fileData = ConvertTo-Base64String -InputObject $bytes
        $ex = $locker.Attachments | Where-Object { $_.FileName -eq $FileName }
        if( $ex ) {
            $ex.Data = $fileData
            $ex.Modified = (Get-Date).ToUniversalTime()
            if( -not (Get-Member -InputObject $ex -Name "GZip") ) {
                Add-Member -InputObject $ex -Name "GZip" -Value $false
            }
            $ex.GZip = $setGZipFlag
        } else {
            $ex = New-PowerPassAttachment
            $ex.FileName = $FileName
            $ex.Data = $fileData
            $ex.GZip = $setGZipFlag
            $locker.Attachments += $ex
        }
    } end {
        Out-PowerPassLocker -Locker $locker
    }
}

function Remove-PowerPassAttachment {
    <#
        .SYNOPSIS
        Removes an attachment from your locker.
        .PARAMETER FileName
        The filename of the attachment to remove from your locker.
        .NOTES
        The filename parameter can be passed from the pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $FileName
    )
    begin {
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
        if( -not $locker ) {
            throw "Could not load your PowerPass locker"
        }
        $newLocker = New-PowerPassLocker
        # Old lockers do not have a Modified flag
        if( $locker.Modified ) {
            $newLocker.Modified = $locker.Modified
        }
        $newLocker.Created = $locker.Created
        $newLocker.Secrets = $locker.Secrets
        $changed = $false
    } process {
        foreach( $s in $locker.Attachments ) {
            if( ($s.FileName) -eq $FileName ) {
                $s.Mfd = $true
                $changed = $true
            }
        }
    } end {
        if( $changed ) {
            $newLocker.Attachments = $locker.Attachments | Where-Object { -not ($_.Mfd) }
            Out-PowerPassLocker -Locker $newLocker
        }
    }
}

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
    [PSCustomObject]$locker = $null
    Get-PowerPassLocker -Locker ([ref] $locker)
    if( -not $locker ) {
        throw "Could not create or fetch your locker"
    }
    if( $locker.Secrets ) {
        foreach( $s in $locker.Secrets ) {
            if( $Match ) {
                if( $s.Title -like $Match ) {
                    Unlock-PowerPassSecret $s
                    if( $PlainTextPasswords ) {
                        Write-Output $s
                    } else {
                        if( $AsCredential ) {
                            Get-PowerPassCredential $s
                        } else {
                            Set-PowerPassSecureString $s
                        }
                    }
                }
            } elseif( $Title ) {
                if( $s.Title -eq $Title ) {
                    Unlock-PowerPassSecret $s
                    if( $PlainTextPasswords ) {
                        Write-Output $s
                    } else {
                        if( $AsCredential ) {
                            Get-PowerPassCredential $s
                        } else {
                            Set-PowerPassSecureString $s
                        }
                    }
                }
            } else {
                Unlock-PowerPassSecret $s
                if( $PlainTextPasswords ) {
                    Write-Output $s
                } else {
                    if( $AsCredential ) {
                        Get-PowerPassCredential $s
                    } else {
                        Set-PowerPassSecureString $s
                    }
                }
            }
        }
    }
}

function Write-PowerPassSecret {
    <#
        .SYNOPSIS
        Writes a secret into your PowerPass locker.
        .PARAMETER Title
        Mandatory. The Title of the secret. This is unique to your locker. If you already have a secret in your
        locker with this Title, it will be updated, but only the parameters you specify will be updated.
        .PARAMETER UserName
        Optional. Sets the UserName property of the secret in your locker.
        .PARAMETER Password
        Optional. Sets the Password property of the secret in your locker.
        .PARAMETER URL
        Optional. Sets the URL property of the secret in your locker.
        .PARAMETER Notes
        Optional. Sets the Notes property of the secret in your locker.
        .PARAMETER Expires
        Optional. Sets the Expiras property of the secret in your locker.
        .PARAMETER MaskPassword
        An optional switch that, when specified, will prompt you to enter a password rather than having to use the Password parameter.
    #>
    param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName,Position=0)]
        [string]
        $Title,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $UserName,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Password,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $URL,
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]
        $Notes,
        [Parameter(ValueFromPipelineByPropertyName)]
        [DateTime]
        $Expires = [DateTime]::MaxValue,
        [switch]
        $MaskPassword
    )
    begin {
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
        if( -not $locker ) {
            throw "Could not create or fetch your locker"
        }
        $changed = $false
        New-Variable -Name EphemeralKey -Value (Get-PowerPassEphemeralKey) -Scope Script
    } process {
        $existingSecret = $locker.Secrets | Where-Object { $_.Title -eq $Title }
        if( $existingSecret ) {
            if( $UserName ) {
                $existingSecret.UserName = Lock-PowerPassString $UserName
                $changed = $true
            }
            if( $Password ) {
                $existingSecret.Password = Lock-PowerPassString $Password
                $changed = $true
            }
            if( $MaskPassword ) {
                $existingSecret.Password = Get-PowerPassMaskedPassword -Prompt "Enter the Password for the secret" | Lock-PowerPassString
                $changed = $true
            }
            if( $URL ) {
                $existingSecret.URL = Lock-PowerPassString $URL
                $changed = $true
            }
            if( $Notes ) {
                $existingSecret.Notes = Lock-PowerPassString $Notes
                $changed = $true
            }
            if( $Expires -ne ($existing.Expires) ) {
                $existingSecret.Expires = $Expires
                $changed = $true
            }
            if( $changed ) {
                $existingSecret.Modified = (Get-Date).ToUniversalTime()
            }
        } else {
            $changed = $true
            $newSecret = New-PowerPassSecret
            $newSecret.Title = $Title
            $newSecret.UserName = Lock-PowerPassString $UserName
            $newSecret.Password = Lock-PowerPassString $Password
            if( $MaskPassword ) {
                $newSecret.Password = Get-PowerPassMaskedPassword -Prompt "Enter the Password for the secret" | Lock-PowerPassString
                $changed = $true
            }
            $newSecret.URL = Lock-PowerPassString $URL
            $newSecret.Notes = Lock-PowerPassString $Notes
            $newSecret.Expires = $Expires
            $locker.Secrets += $newSecret
        }
    } end {
        [PowerPass.AesCrypto]::EraseBuffer( $script:EphemeralKey )
        Remove-Variable -Name EphemeralKey -Scope Script
        if( $changed ) {
            Out-PowerPassLocker -Locker $locker
        }
    }
}

function Remove-PowerPassSecret {
    <#
        .SYNOPSIS
        Removes a secret from your locker.
        .PARAMETER Title
        The Title of the secret to remove from your locker.
        .NOTES
        The Title parameter can be passed from the pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $Title
    )
    begin {
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
        if( -not $locker ) {
            throw "Could not load your PowerPass locker"
        }
        $newLocker = New-PowerPassLocker
        # Old lockers do not have a Modified flag
        if( $locker.Modified ) {
            $newLocker.Modified = $locker.Modified
        }
        $newLocker.Created = $locker.Created
        $newLocker.Attachments = $locker.Attachments
        $changed = $false
    } process {
        foreach( $s in $locker.Secrets ) {
            if( ($s.Title) -eq $Title ) {
                $s.Mfd = $true
                $changed = $true
            }
        }
    } end {
        if( $changed ) {
            $newLocker.Secrets = $locker.Secrets | Where-Object { -not ($_.Mfd) }
            Out-PowerPassLocker -Locker $newLocker
        }
    }
}

function Export-PowerPassAttachment {
    <#
        .SYNOPSIS
        Exports one or more attachments from your locker.
        .PARAMETER FileName
        The filename of the attachment to fetch. Supports wildcard matching.
        .PARAMETER Path
        The Path to the directory to output the file(s). Overrides LiteralPath.
        .PARAMETER LiteralPath
        The LiteralPath to the directory to output the file(s).
        .PARAMETER OriginalPath
        An optional switch that, when specified, uses the path of the file in the locker,
        assuming that file in the locker has a full path, otherwise the file will be
        exprted to the current directory. Cannot be combined with Path or LiteralPath.
        .PARAMETER Force
        An optional switch that will force-overwrite any existing files on disk.
        .OUTPUTS
        This cmdlet outputs the FileInfo for each exported file.
    #>
    [CmdletBinding(DefaultParameterSetName="Default")]
    param(
        [Parameter(ParameterSetName="Default",Mandatory,ValueFromPipeline,Position=0)]
        [Parameter(ParameterSetName="Path",Mandatory,ValueFromPipeline,Position=0)]
        [Parameter(ParameterSetName="LiteralPath",Mandatory,ValueFromPipeline,Position=0)]
        [Parameter(ParameterSetName="OriginalPath",Mandatory,ValueFromPipeline,Position=0)]
        [string]
        $FileName,
        [Parameter(ParameterSetName="Path",Position=1)]
        [string]
        $Path,
        [Parameter(ParameterSetName="LiteralPath",Position=1)]
        [string]
        $LiteralPath,
        [Parameter(ParameterSetName="OriginalPath")]
        [switch]
        $OriginalPath,
        [switch]
        $Force
    )
    begin {
        [PSCustomObject]$locker = $null
        Get-PowerPassLocker -Locker ([ref] $locker)
        if( -not $locker ) {
            throw "Could not create or fetch your locker"
        }
        $targetDir = Get-Item -Path "."
        $testDir = if( $Path ) {
            $Path
        } elseif( $LiteralPath ) {
            $LiteralPath
        } else {
            $null
        }
        if( $testDir ) {
            $pathInfo = Get-Item -Path $testDir
            if( $pathInfo ) {
                switch( ($pathInfo.GetType()).FullName ) {
                    "System.IO.DirectoryInfo" {
                        $targetDir = $pathInfo
                    }
                    default {
                        throw "Output target is not a directory"
                    }
                }
            } else {
                throw "Specified path does not exist"
            }
        }
    }
    process {
        $atts = $locker.Attachments | Where-Object { $_.FileName -like $FileName }
        foreach( $a in $atts ) {
            [byte[]]$bytes = ConvertFrom-Base64String -InputString $a.Data
            if( $a.GZip ) {
                $bytes = [PowerPass.Compressor]::DecompressBytes( $bytes )
            }         
            $targetFile = if( $OriginalPath ) {
                $a.FileName
            } else {
                Join-Path -Path ($targetDir.FullName) -ChildPath ($a.FileName)
            }
            if( $Force ) {
                Write-AllFileBytes -InputObject $bytes -LiteralPath $targetFile
                Write-Output (Get-Item -LiteralPath $targetFile)
            } else {
                if( Test-Path $targetFile ) {
                    $answer = Read-Host "$targetFile already exists, overwrite? [N/y]"
                    if( $answer -eq 'y' ) {
                        Write-AllFileBytes -InputObject $bytes -LiteralPath $targetFie
                        Write-Output (Get-Item -LiteralPath $targetFile)
                    }
                } else {
                    Write-AllFileBytes -InputObject $bytes -LiteralPath $targetFile
                    Write-Output (Get-Item -LiteralPath $targetFile)
                }
            }
        }
    }
}

function Get-PowerPassEphemeralKey {
    <#
        .SYNOPSIS
        Creates an ephemeral key from the host, user, and active network adapter.
        .DESCRIPTION
        Very few cryptographically strong identifiers for the current operating environment
        of PowerShell exist across all operating systems which support PowerShell. The processor
        ID, for example, requires elevated privileges. As such, in order to create a moderately
        strong key to encrypt the AES key used to encrypt the PowerPass Locker, we build a
        composite key using the hostname, user name, domain name (if there is one), and the MAC
        address of the primary, active network adapter, all of which can be accessed from user
        space without elevated permissions and all of which are highly unlikely to change. For
        an attacker to successfully guess the key for an encrypted AES key they would need to know
        what user generated the key and on what specific machine. The MAC address adds entropy
        which makes a brute-force attack more difficult. And chances are if an attacker
        compromised a user's private home directory they will already know the user's name and
        computer name, but if they can no longer access the machine they will not be able to get
        the final component the MAC address to unlock the key. The same applies if the key was
        compromised from a remote system, like a cloud share, where the attacker does not know
        where it came from, and thus only a brute-force attack would be possible.
    #>

    # Setup the composite key variables
    [string]$hostName = [System.Environment]::MachineName
    [string]$userName = [System.Environment]::UserName
    [string]$domainName = [System.Environment]::UserDomainName
    if( -not $domainName ) { $domainName = "none" }
    [string]$macAddress = "00:00:00:00:00:00"

    # Define the types of network adapters which contain MAC addresses we are looking for
    $macTypes = @("Ethernet","FastEthernetFx","FastEthernetT","GigabitEthernet","Wireless80211")

    # Search through all network interfaces for candidates
    $adapters = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()
    $candidates = @()
    foreach( $nic in $adapters ) {
        $notExcluded = ($nic.Description -notlike "awdl*") -and ($nic.Description -notlike "llw*")
        $online = $nic.OperationalStatus -eq "Up"
        $matching = $nic.NetworkInterfaceType -in $macTypes
        if( $notExcluded -and $online -and $matching ) {
            $candidates += $nic
        }
    }

    # Sort by description and pick the top result
    if( $candidates ) {
        $nics = $candidates | Sort-Object { $_.Description }
        $macAddress = $nics[0].GetPhysicalAddress()
    } else {
        Write-Warning "Security warning, no active network adapters"
    }
    
    # Build the ephemeral key from the composite parts
    $compKey = "$hostName|$userName|$domainName|$macAddress"
    $compKeyBytes = ConvertTo-Utf8ByteArray -InputString $compKey
    $sha = [System.Security.Cryptography.Sha256]::Create()
    Write-Output $sha.ComputeHash( $compKeyBytes )
}

function Lock-PowerPassString {
    <#
        .SYNOPSIS
        Encrypts a string using the ephemeral key as a one-time pad.
        .PARAMETER InputObject
        The input string object to encrypt.
    #>
    param(
        [Parameter(ValueFromPipeline,Position = 0)]
        [string]
        $InputObject
    )
    if( -not $InputObject ) {
        return
    }
    $ek = $script:EphemeralKey
    if( -not $ek ) {
        throw "Ephemeral key not initialized"
    }
    $eki = 0
    $ca = [System.Text.Encoding]::UTF8.GetBytes( $InputObject )
    $ea = [System.Array]::CreateInstance( [System.Byte], $ca.Length )
    for( $cai = 0; $cai -lt $ca.Length; $cai++ ) {
        [UInt16]$cau = ($ca[$cai])
        [UInt16]$eku = ($ek[$eki])
        [byte]$cae = ($cau + $eku) % 256
        $ea[$cai] = $cae
        $eki++
        if( $eki -ge $ek.Length ) {
            $eki = 0
        }
    }
    [PowerPass.AesCrypto]::EraseBuffer( $ca )
    Write-Output (ConvertTo-Base64String -InputObject $ea)
}

function Unlock-PowerPassString {
    <#
        .SYNOPSIS
        Decrypts a string encrypted with the ephemeral key as a one-time pad.
        .PARAMETER InputObject
        The encrypted string.
    #>
    param(
        [Parameter(ValueFromPipeline,Position = 0)]
        [string]
        $InputObject
    )
    if( -not $InputObject ) {
        return
    }
    $ek = $script:EphemeralKey
    if( -not $ek ) {
        throw "Ephemeral key not initialized"
    }
    $eki = 0
    $ea = ConvertFrom-Base64String -InputString $InputObject
    $ca = [System.Array]::CreateInstance( [System.Byte], $ea.Length )
    for( $eai = 0; $eai -lt $ea.Length; $eai++ ) {
        [Int16]$eau = $ea[$eai]
        [Int16]$eku = $ek[$eki]
        [Int16]$cas = $eau - $eku
        [byte]$cau = if( $cas -lt 0 ) { $cas + 256 } else { $cas }
        $ca[$eai] = $cau
        $ea[$eai] = 0
        $eki++
        if( $eki -ge $ek.Length ) {
            $eki = 0
        }
    }
    Write-Output ([System.Text.Encoding]::UTF8.GetString($ca))
}

function Unlock-PowerPassSecret {
    <#
        .SYNOPSIS
        Unlocks the UserName, Password, URL and Notes fields for a Locker secret.
        .PARAMETER Secret
        The secret to unlock.
    #>
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position = 0)]
        [PSCustomObject]
        $Secret
    )
    begin {
        New-Variable -Name EphemeralKey -Value (Get-PowerPassEphemeralKey) -Scope Script
    } process {
        if( $Secret.UserName ) {
            $Secret.UserName = Unlock-PowerPassString ($Secret.UserName)
        }
        if( $Secret.Password ) {
            $Secret.Password = Unlock-PowerPassString ($Secret.Password)
        }
        if( $Secret.URL ) {
            $Secret.URL = Unlock-PowerPassString ($Secret.URL)
        }
        if( $Secret.Notes ) {
            $Secret.Notes = Unlock-PowerPassString ($Secret.Notes)
        }
    } end {
        [PowerPass.AesCrypto]::EraseBuffer( $script:EphemeralKey )
        Remove-Variable -Name EphemeralKey -Scope Script
    }
}

function Lock-PowerPassSecret {
    <#
        .SYNOPSIS
        Locks the UserName, Password, URL and Notes field of a Locker secret.
        .PARAMETER Secret
        The secret to lock.
    #>
    param(
        [Parameter(Mandatory,ValueFromPipeline,Position = 0)]
        [PSCustomObject]
        $Secret
    )
    begin {
        New-Variable -Name EphemeralKey -Value (Get-PowerPassEphemeralKey) -Scope Script
    } process {
        if( $Secret.UserName ) {
            $Secret.UserName = Lock-PowerPassString ($Secret.UserName)
        }
        if( $Secret.Password ) {
            $Secret.Password = Lock-PowerPassString ($Secret.Password)
        }
        if( $Secret.URL ) {
            $Secret.URL = Lock-PowerPassString ($Secret.URL)
        }
        if( $Secret.Notes ) {
            $Secret.Notes = Lock-PowerPassString ($Secret.Notes)
        }
    } end {
        [PowerPass.AesCrypto]::EraseBuffer( $script:EphemeralKey )
        Remove-Variable -Name EphemeralKey -Scope Script
    }
}

function Read-PowerPassPassword {
    <#
        .SYNOPSIS
        Prompts the user to enter a password.
    #>
    if( $PSVersionTable.PSVersion.Major -eq 5 ) {
        $secString = Read-Host "Enter a password (4 - 32 characters)" -AsSecureString
        $bString = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $secString )
        $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto( $bString )
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR( $bString )
    } else {
        $password = Read-Host -Prompt "Enter a locker password (4 - 32 characters)" -MaskInput
    }
    if( $password -eq "" ) {
        throw "You cannot use a blank password"
    }
    if( ($password.Length -lt 4) -or ($password.Length -gt 32) ) {
        throw "The password must be between 4 and 32 characters."
    }
    Write-Output $password
}

function Update-PowerPass {
    <#
        .SYNOPSIS
        Checks the Locker for any required updates and runs the updates.
    #>
    [PSCustomObject]$locker = $null
    Get-PowerPassLocker -Locker ([ref] $locker)
    if( -not $locker ) {
        throw "Failed to open Locker"
    }
    if( $locker.Revision ) {
        switch( $locker.Revision ) {
            3 {
                Write-Output "Your Locker is up to date"
            }
            default {
                Write-Warning "Your Locker has an unknown rev number"
            }
        }
    } else {
        # Revision flag added in version 3: text values are encrypted with a one-time pad
        $newLocker = New-PowerPassLocker
        $newLocker.Created = $locker.Created
        # Rev 1 Lockers do not have the Modified flag
        if( $locker.Modified ) {
            $newLocker.Modified = $locker.Modified
        }
        $newLocker.Secrets = $locker.Secrets
        $newLocker.Attachments = $locker.Attachments
        $newLocker.Secrets | Lock-PowerPassSecret
        Out-PowerPassLocker -Locker $newLocker
        Write-Output "Your Locker has been upgraded to rev 3"
    }
}

function Merge-PowerPassLockers {
    <#
        .SYNOPSIS
        Merges the contents of two Lockers.
        .PARAMETER From
        The source locker.
        .PARAMETER To
        The target locker.
        .PARAMETER ByDate
        An optional switch to merge if newer.
    #>
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]
        $From,
        [Parameter(Mandatory)]
        [PSCustomObject]
        $To,
        [switch]
        $ByDate
    )

    # Declare the output flag
    $modified = $false

    # Merge in the secrets collection
    foreach( $secret in $from.Secrets ) {
        $existing = $to.Secrets | Where-Object { $_.Title -eq ($secret.Title) }
        if( $existing ) {
            $shouldUpdate = if( $ByDate ) { (Get-PowerPassIsNewer -Ours $existing -Theirs $secret) } else { $true }
            if( $shouldUpdate ) {
                $existing.UserName = $secret.UserName
                $existing.Password = $secret.Password
                $existing.URL = $secret.URL
                $existing.Notes = $secret.Notes
                $existing.Expires = $secret.Expires
                $existing.Modified = (Get-Date).ToUniversalTime()
                Lock-PowerPassSecret $existing
                $modified = $true
            }
        } else {
            Lock-PowerPassSecret $secret
            $to.Secrets += $secret
            $modified = $true
        }
    }

    # Merge in the attachments collection
    foreach( $a in $from.Attachments ) {
        $existing = $to.Attachments | Where-Object { $_.FileName -eq ($a.FileName) }
        if( $existing ) {
            $shouldUpdate = if( $ByDate ) { (Get-PowerPassIsNewer -Ours $existing -Theirs $a) } else { $true }
            if( $shouldUpdate ) {
                $existing.Data = $a.Data
                $existing.Created = $a.Created
                $existing.Modified = $a.Modified
                if( $a.GZip ) {
                    $existing.GZip = $a.GZip
                } else {
                    $existing.GZip = $false
                }
                $modified = $true
            }
        } else {
            $to.Attachments += $a
            $modified = $true
        }
    }

    # Notify caller of changes
    Write-Output $modified
}