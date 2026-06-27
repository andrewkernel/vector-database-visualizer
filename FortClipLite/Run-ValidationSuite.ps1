param(
    [int]$SmokeSeconds = 8
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$MainScript = Join-Path $AppRoot "FortClipLite.ps1"
$ReportsDir = Join-Path $AppRoot "reports"
New-Item -ItemType Directory -Force -Path $ReportsDir | Out-Null

function Quote-ProcessArgument {
    param([Parameter(Mandatory)][string]$Argument)
    if ($Argument -notmatch '[\s"]') {
        return $Argument
    }
    return '"' + ($Argument -replace '"', '\"') + '"'
}

function Join-ProcessArguments {
    param([Parameter(Mandatory)][string[]]$Arguments)
    return (($Arguments | ForEach-Object { Quote-ProcessArgument -Argument $_ }) -join " ")
}

function Invoke-CaptureProcess {
    param(
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)][string[]]$Arguments,
        [int]$TimeoutMilliseconds = 180000
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FileName
    $psi.Arguments = Join-ProcessArguments -Arguments $Arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()

    if (-not $process.WaitForExit($TimeoutMilliseconds)) {
        try { $process.Kill() } catch {}
        return [pscustomobject]@{
            ExitCode = 124
            StdOut = $stdoutTask.Result
            StdErr = "Timed out after $TimeoutMilliseconds ms."
        }
    }

    $process.WaitForExit()
    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = $stdoutTask.Result
        StdErr = $stderrTask.Result
    }
}

function Invoke-FortClipTest {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string[]]$Arguments,
        [int]$TimeoutMilliseconds = 180000
    )

    Write-Host "Running $Name..."
    $started = Get-Date
    $result = Invoke-CaptureProcess -FileName "powershell.exe" -Arguments $Arguments -TimeoutMilliseconds $TimeoutMilliseconds
    $ended = Get-Date
    return [pscustomobject]@{
        Name = $Name
        Passed = ($result.ExitCode -eq 0)
        ExitCode = $result.ExitCode
        StartedAt = $started.ToString("o")
        EndedAt = $ended.ToString("o")
        DurationSeconds = [Math]::Round(($ended - $started).TotalSeconds, 2)
        StdOut = $result.StdOut.Trim()
        StdErr = $result.StdErr.Trim()
    }
}

$base = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MainScript)
$tests = @(
    [pscustomobject]@{
        Name = "Compatibility probe"
        Arguments = $base + @("-CompatibilityReport", "-ProbeCapture")
        Timeout = 60000
    },
    [pscustomobject]@{
        Name = "Default hardware-preferred smoke"
        Arguments = $base + @("-SmokeTest", "-SmokeSeconds", "$SmokeSeconds")
        Timeout = 180000
    },
    [pscustomobject]@{
        Name = "CPU-only fallback smoke"
        Arguments = $base + @("-SmokeTest", "-SmokeSeconds", "$SmokeSeconds", "-SmokeCaptureMode", "gdigrab", "-SmokeEncoder", "libx264", "-SmokeAudioMode", "silent")
        Timeout = 180000
    }
)

$results = foreach ($test in $tests) {
    Invoke-FortClipTest -Name $test.Name -Arguments $test.Arguments -TimeoutMilliseconds $test.Timeout
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonPath = Join-Path $ReportsDir "validation_$stamp.json"
$mdPath = Join-Path $ReportsDir "validation_$stamp.md"
$passed = -not ($results | Where-Object { -not $_.Passed })

[pscustomobject]@{
    Passed = $passed
    GeneratedAt = (Get-Date).ToString("o")
    Machine = $env:COMPUTERNAME
    User = $env:USERNAME
    SmokeSeconds = $SmokeSeconds
    Results = $results
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonPath -Encoding UTF8

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# FortClipLite Validation Report")
$lines.Add("")
$lines.Add("- Generated: $(Get-Date -Format o)")
$lines.Add("- Machine: $env:COMPUTERNAME")
$lines.Add("- Overall: $(if ($passed) { 'PASS' } else { 'FAIL' })")
$lines.Add("")
foreach ($result in $results) {
    $lines.Add("## $($result.Name)")
    $lines.Add("")
    $lines.Add("- Result: $(if ($result.Passed) { 'PASS' } else { 'FAIL' })")
    $lines.Add("- Exit code: $($result.ExitCode)")
    $lines.Add("- Duration: $($result.DurationSeconds)s")
    if ($result.StdOut) {
        $lines.Add("")
        $lines.Add('```text')
        $lines.Add($result.StdOut)
        $lines.Add('```')
    }
    if ($result.StdErr) {
        $lines.Add("")
        $lines.Add("Errors:")
        $lines.Add("")
        $lines.Add('```text')
        $lines.Add($result.StdErr)
        $lines.Add('```')
    }
    $lines.Add("")
}

$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8

Write-Host ""
Write-Host "Validation report:"
Write-Host $mdPath
Write-Host $jsonPath

if (-not $passed) {
    exit 1
}
