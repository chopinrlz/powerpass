# Create a random number generator and results collection
$rand = [System.Random]::new()
$testResults = @()
$iterations = 12
$step = 32 * 1024 * 1024

# Run a test in $step KiB increments
1..$iterations | ForEach-Object {

    # Write a progress window
    Write-Progress -Activity "Testing Base64 Conversion" -Status "Iteration $_ of $iterations" -PercentComplete (($_ / $iterations) * 99.9)

    # Create a test result
    $dataLength = ($_ * $step)
    $result = [PSCustomObject]@{
        Length = $dataLength
        FillMs = 0
        ToBase64Ms = 0
        FromBase64Ms = 0
    }

    # Create an array of data
    $start = Get-Date
    [byte[]]$data = [System.Array]::CreateInstance( [byte[]], $dataLength )
    $rand.NextBytes( $data )
    $result.FillMs = ((Get-Date) - $start).TotalMilliseconds

    # Run conversion tests and track timing
    $start = Get-Date
    $base64 = [System.Convert]::ToBase64String( $data )
    $result.ToBase64Ms = ((Get-Date) - $start).TotalMilliseconds

    $start = Get-Date
    $bytes = [System.Convert]::FromBase64String( $base64 )
    $result.FromBase64Ms = ((Get-Date) - $start).TotalMilliseconds

    # Record results for output and graphing
    $testResults += $result

    # Erase everything and start over
    $data = $null
    $base64 = $null
    $bytes = $null
    [GC]::Collect()
}

# Output the results to CSV
$testResults | Export-Csv "base64-results.csv" -Force