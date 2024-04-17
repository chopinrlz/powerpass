# Create a random number generator and results collection
$rand = [System.Random]::new()
$testResults = @()
$iterations = 4 * 1024
$step = 1 * 1024

# Fill a byte[] with random data for testing
[byte[]]$randomData = [System.Array]::CreateInstance( [byte[]], $iterations * $step )
$rand.NextBytes( $randomData )

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
    [System.Array]::Copy( $randomData, 0, $data, 0, $dataLength )
    $result.FillMs = ((Get-Date) - $start).TotalMilliseconds

    # Run conversion tests and track timing
    $start = Get-Date
    $base64 = [System.Convert]::ToBase64String( $data )
    $result.ToBase64Ms = ((Get-Date) - $start).TotalMilliseconds

    $start = Get-Date
    $chars = $base64.ToCharArray()
    $bytes = [System.Convert]::FromBase64CharArray( $chars, 0, $chars.Length )
    $result.FromBase64Ms = ((Get-Date) - $start).TotalMilliseconds

    # Record results for output and graphing
    $testResults += $result
}

# Output the results to CSV
$testResults | Export-Csv "base64-results.csv" -Force