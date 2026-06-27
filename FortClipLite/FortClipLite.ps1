param(
    [switch]$SelfTest,
    [switch]$ListAudioDevices,
    [switch]$CompatibilityReport,
    [switch]$ProbeCapture,
    [switch]$SmokeTest,
    [int]$SmokeSeconds = 8,
    [switch]$KeepSmokeClip,
    [string]$SmokeCaptureMode = "",
    [string]$SmokeEncoder = "",
    [string]$SmokeAudioMode = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AppName = "FortClipLite"
$AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $AppRoot "config.json"
$BufferDir = Join-Path $AppRoot "buffer"
$DefaultClipDir = Join-Path $AppRoot "clips"

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class NativeHotKey {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
}
"@

$DefaultConfig = [ordered]@{
    Enabled = $false
    ClipSeconds = 30
    SegmentSeconds = 2
    Width = 1920
    Height = 1080
    Fps = 60
    BitrateMbps = 35
    Encoder = "auto"
    CaptureMode = "auto"
    DisplayIndex = 0
    IncludeMouse = $false
    AudioMode = "auto"
    AudioDevice = ""
    AudioFallback = "silent"
    AudioBitrateKbps = 160
    Hotkey = "Ctrl+Alt+F10"
    ClipDirectory = $DefaultClipDir
    FfmpegPath = ""
}

function ConvertTo-Hashtable {
    param([Parameter(Mandatory)]$InputObject)
    $hash = [ordered]@{}
    foreach ($property in $InputObject.PSObject.Properties) {
        $hash[$property.Name] = $property.Value
    }
    return $hash
}

function Load-Config {
    $config = [ordered]@{}
    foreach ($key in $DefaultConfig.Keys) {
        $config[$key] = $DefaultConfig[$key]
    }

    if (Test-Path $ConfigPath) {
        $loaded = ConvertTo-Hashtable (Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json)
        foreach ($key in $loaded.Keys) {
            $config[$key] = $loaded[$key]
        }
    }

    return $config
}

function Save-Config {
    param([Parameter(Mandatory)]$Config)
    $Config | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
}

function Ensure-Directories {
    param([Parameter(Mandatory)]$Config)
    New-Item -ItemType Directory -Force -Path $BufferDir | Out-Null
    New-Item -ItemType Directory -Force -Path $Config.ClipDirectory | Out-Null
}

function Resolve-FfmpegPath {
    param([Parameter(Mandatory)]$Config)
    if ($Config.FfmpegPath -and (Test-Path -LiteralPath $Config.FfmpegPath)) {
        return (Resolve-Path -LiteralPath $Config.FfmpegPath).Path
    }

    $localFfmpeg = Join-Path $AppRoot "bin\ffmpeg.exe"
    if (Test-Path -LiteralPath $localFfmpeg) {
        return (Resolve-Path -LiteralPath $localFfmpeg).Path
    }

    $cmd = Get-Command ffmpeg.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $wingetRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path -LiteralPath $wingetRoot) {
        $wingetFfmpeg = Get-ChildItem -LiteralPath $wingetRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*FFmpeg*" } |
            ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Recurse -Filter "ffmpeg.exe" -File -ErrorAction SilentlyContinue } |
            Select-Object -First 1
        if ($wingetFfmpeg) {
            return $wingetFfmpeg.FullName
        }
    }

    throw "ffmpeg.exe was not found. Install FFmpeg or set FfmpegPath in config.json."
}

function Resolve-FfprobePath {
    param([Parameter(Mandatory)][string]$Ffmpeg)

    $candidate = Join-Path (Split-Path -Parent $Ffmpeg) "ffprobe.exe"
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    $cmd = Get-Command ffprobe.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    return ""
}

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

function Invoke-ProcessCapture {
    param(
        [Parameter(Mandatory)][string]$FileName,
        [Parameter(Mandatory)][string[]]$Arguments,
        [int]$TimeoutMilliseconds = 10000
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FileName
    $psi.Arguments = Join-ProcessArguments -Arguments $Arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    $p = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $p.StandardOutput.ReadToEndAsync()
    $stderrTask = $p.StandardError.ReadToEndAsync()

    if (-not $p.WaitForExit($TimeoutMilliseconds)) {
        try { $p.Kill() } catch {}
        throw "Timed out while running $FileName."
    }
    $p.WaitForExit()

    return [pscustomobject]@{
        ExitCode = $p.ExitCode
        StdOut = $stdoutTask.Result
        StdErr = $stderrTask.Result
    }
}

function Get-EncoderList {
    param([Parameter(Mandatory)][string]$Ffmpeg)
    $output = & $Ffmpeg -hide_banner -encoders 2>&1
    return ($output -join "`n")
}

function Get-DshowAudioDevices {
    param([Parameter(Mandatory)][string]$Ffmpeg)

    $result = Invoke-ProcessCapture -FileName $Ffmpeg -Arguments @("-hide_banner", "-list_devices", "true", "-f", "dshow", "-i", "dummy")
    $output = @($result.StdOut -split "`r?`n") + @($result.StdErr -split "`r?`n")
    $devices = New-Object System.Collections.Generic.List[string]
    $pendingAudioName = ""
    foreach ($line in $output) {
        $text = [string]$line
        if ($text -match '"(.+)"\s+\(audio\)') {
            $pendingAudioName = $matches[1]
            continue
        }
        if ($pendingAudioName -and $text -match 'Alternative name "(.+)"') {
            $devices.Add($matches[1])
            $pendingAudioName = ""
            continue
        }
        if ($pendingAudioName -and $text -match '"(.+)"\s+\(') {
            $devices.Add($pendingAudioName)
            $pendingAudioName = ""
        }
    }
    if ($pendingAudioName) {
        $devices.Add($pendingAudioName)
    }
    return @($devices | Select-Object -Unique)
}

function Select-Encoder {
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$Ffmpeg
    )

    if ($Config.Encoder -and $Config.Encoder -ne "auto") {
        return $Config.Encoder
    }

    $candidates = Get-EncoderCandidates -Config $Config -Ffmpeg $Ffmpeg
    if ($candidates.Count -gt 0) {
        return $candidates[0]
    }

    throw "No usable H.264 encoder was reported by FFmpeg."
}

function Get-EncoderCandidates {
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$Ffmpeg
    )

    if ($Config.Encoder -and $Config.Encoder -ne "auto") {
        return @([string]$Config.Encoder)
    }

    $encoders = Get-EncoderList -Ffmpeg $Ffmpeg
    $usable = New-Object System.Collections.Generic.List[string]
    foreach ($candidate in @("h264_nvenc", "h264_amf", "h264_qsv", "h264_mf", "libx264")) {
        if ($encoders -match [regex]::Escape($candidate) -and (Test-EncoderCandidate -Encoder $candidate -Ffmpeg $Ffmpeg -Config $Config)) {
            $usable.Add($candidate)
        }
    }
    return @($usable)
}

function Test-EncoderCandidate {
    param(
        [Parameter(Mandatory)][string]$Encoder,
        [Parameter(Mandatory)][string]$Ffmpeg,
        [Parameter(Mandatory)]$Config
    )

    $args = @(
        "-hide_banner", "-loglevel", "error", "-y",
        "-f", "lavfi", "-i", "nullsrc=s=1280x720:r=1",
        "-frames:v", "1"
    )
    $args += Get-EncoderArguments -Encoder $Encoder -Config $Config
    $args += @("-f", "null", "NUL")

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Ffmpeg
    $psi.Arguments = Join-ProcessArguments -Arguments $args
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardError = $true

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        if (-not $p.WaitForExit(5000)) {
            $p.Kill()
            return $false
        }
        return $p.ExitCode -eq 0
    } catch {
        return $false
    }
}

function Get-EncoderArguments {
    param(
        [Parameter(Mandatory)][string]$Encoder,
        [Parameter(Mandatory)]$Config
    )

    $bitrate = "{0}M" -f [int]$Config.BitrateMbps
    $maxrate = "{0}M" -f ([int]$Config.BitrateMbps * 2)
    $bufsize = "{0}M" -f [int]$Config.BitrateMbps
    $gop = [int]$Config.Fps

    switch -Regex ($Encoder) {
        "nvenc" {
            return @("-c:v", $Encoder, "-preset", "p1", "-tune", "ull", "-rc", "vbr", "-cq", "19", "-b:v", $bitrate, "-maxrate", $maxrate, "-bufsize", $bufsize, "-g", "$gop", "-bf", "0", "-forced-idr", "1")
        }
        "amf" {
            return @("-c:v", $Encoder, "-quality", "speed", "-usage", "lowlatency", "-rc", "vbr_peak", "-b:v", $bitrate, "-maxrate", $maxrate, "-g", "$gop", "-bf", "0")
        }
        "qsv" {
            return @("-c:v", $Encoder, "-preset", "veryfast", "-look_ahead", "0", "-b:v", $bitrate, "-maxrate", $maxrate, "-g", "$gop", "-bf", "0")
        }
        "d3d12va|mf" {
            return @("-c:v", $Encoder, "-b:v", $bitrate, "-g", "$gop")
        }
        default {
            return @("-c:v", "libx264", "-preset", "ultrafast", "-tune", "zerolatency", "-b:v", $bitrate, "-maxrate", $maxrate, "-bufsize", $bufsize, "-g", "$gop")
        }
    }
}

function Get-CaptureArguments {
    param([Parameter(Mandatory)]$Config)

    $fps = [int]$Config.Fps
    $drawMouse = if ($Config.IncludeMouse) { 1 } else { 0 }
    $displayIndex = [int]$Config.DisplayIndex

    if ($Config.CaptureMode -eq "gdigrab") {
        return @(
            "-f", "gdigrab",
            "-framerate", "$fps",
            "-draw_mouse", "$drawMouse",
            "-i", "desktop"
        )
    }

    $source = "ddagrab=output_idx=${displayIndex}:framerate=${fps}:draw_mouse=${drawMouse}"
    return @(
        "-f", "lavfi",
        "-i", $source
    )
}

function Get-VideoFilterArguments {
    param([Parameter(Mandatory)]$Config)

    $w = [int]$Config.Width
    $h = [int]$Config.Height
    if ($Config.CaptureMode -eq "gdigrab") {
        return @("-vf", "scale=${w}:${h}:flags=fast_bilinear,format=yuv420p")
    }
    return @("-vf", "hwdownload,format=bgra,scale=${w}:${h}:flags=fast_bilinear,format=yuv420p")
}

function Get-CaptureCandidates {
    param([Parameter(Mandatory)]$Config)
    if ($Config.CaptureMode -eq "auto") {
        return @("ddagrab", "gdigrab")
    }
    return @([string]$Config.CaptureMode)
}

function Test-CaptureCandidate {
    param(
        [Parameter(Mandatory)][string]$CaptureMode,
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$Ffmpeg
    )

    $probeConfig = Copy-ConfigWith -Config $Config -Overrides @{ CaptureMode = $CaptureMode; Width = 640; Height = 360; Fps = 30 }
    $args = @("-hide_banner", "-loglevel", "error", "-y")
    $args += Get-CaptureArguments -Config $probeConfig
    $args += Get-VideoFilterArguments -Config $probeConfig
    $args += @("-frames:v", "1", "-f", "null", "NUL")

    try {
        $result = Invoke-ProcessCapture -FileName $Ffmpeg -Arguments $args -TimeoutMilliseconds 7000
        return [pscustomobject]@{
            CaptureMode = $CaptureMode
            Works = ($result.ExitCode -eq 0)
            Detail = (($result.StdErr + $result.StdOut).Trim())
        }
    } catch {
        return [pscustomobject]@{
            CaptureMode = $CaptureMode
            Works = $false
            Detail = $_.Exception.Message
        }
    }
}

function Test-AudioCandidate {
    param(
        [Parameter(Mandatory)][string]$AudioDevice,
        [Parameter(Mandatory)][string]$Ffmpeg
    )

    $args = @(
        "-hide_banner", "-loglevel", "error", "-y",
        "-f", "dshow", "-audio_buffer_size", "80", "-i", "audio=$AudioDevice",
        "-t", "1",
        "-f", "null", "NUL"
    )

    try {
        $result = Invoke-ProcessCapture -FileName $Ffmpeg -Arguments $args -TimeoutMilliseconds 8000
        return [pscustomobject]@{
            AudioDevice = $AudioDevice
            Works = ($result.ExitCode -eq 0)
            Detail = (($result.StdErr + $result.StdOut).Trim())
        }
    } catch {
        return [pscustomobject]@{
            AudioDevice = $AudioDevice
            Works = $false
            Detail = $_.Exception.Message
        }
    }
}

function Copy-ConfigWith {
    param(
        [Parameter(Mandatory)]$Config,
        [hashtable]$Overrides = @{}
    )

    $copy = [ordered]@{}
    foreach ($key in $Config.Keys) {
        $copy[$key] = $Config[$key]
    }
    foreach ($key in $Overrides.Keys) {
        $copy[$key] = $Overrides[$key]
    }
    return ,$copy
}

function Get-AudioInputArguments {
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$Ffmpeg
    )

    if ($Config.AudioMode -eq "disabled") {
        return [pscustomobject]@{
            Enabled = $false
            Kind = "disabled"
            Arguments = @()
            Device = ""
            Reason = "disabled"
        }
    }

    if ($Config.AudioMode -eq "silent") {
        return [pscustomobject]@{
            Enabled = $true
            Kind = "silent"
            Arguments = @("-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=48000")
            Device = "silent fallback"
            Reason = "silent fallback"
        }
    }

    $device = [string]$Config.AudioDevice
    $devices = Get-DshowAudioDevices -Ffmpeg $Ffmpeg

    if (-not $device -or $device -eq "auto") {
        $device = @($devices)[0]
    }

    if (-not $device) {
        if ($Config.AudioMode -eq "dshow") {
            throw "Audio is enabled, but no DirectShow audio input was found."
        }
        return [pscustomobject]@{
            Enabled = $false
            Kind = "none"
            Arguments = @()
            Device = ""
            Reason = "no audio device found"
        }
    }

    return [pscustomobject]@{
        Enabled = $true
        Kind = "dshow"
        Arguments = @("-thread_queue_size", "1024", "-f", "dshow", "-audio_buffer_size", "80", "-i", "audio=$device")
        Device = $device
        Reason = ""
    }
}

function Get-AudioAttemptConfigs {
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$Ffmpeg
    )

    if ($Config.AudioMode -eq "disabled") {
        return [pscustomobject]@{ Config = $Config }
    }

    if ($Config.AudioMode -eq "silent") {
        return [pscustomobject]@{ Config = $Config }
    }

    if ($Config.AudioMode -eq "dshow") {
        return [pscustomobject]@{ Config = $Config }
    }

    $attempts = New-Object System.Collections.ArrayList
    if (@(Get-DshowAudioDevices -Ffmpeg $Ffmpeg).Count -gt 0) {
        [void]$attempts.Add([pscustomobject]@{ Config = $Config })
    }

    if ($Config.AudioFallback -eq "silent") {
        [void]$attempts.Add([pscustomobject]@{ Config = (Copy-ConfigWith -Config $Config -Overrides @{ AudioMode = "silent"; AudioDevice = "" }) })
    }

    [void]$attempts.Add([pscustomobject]@{ Config = (Copy-ConfigWith -Config $Config -Overrides @{ AudioMode = "disabled"; AudioDevice = "" }) })
    return @($attempts)
}

function Clear-Buffer {
    if (Test-Path $BufferDir) {
        Get-ChildItem -LiteralPath $BufferDir -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

function Build-RecordArguments {
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$Encoder,
        [Parameter(Mandatory)]$Audio
    )

    $segmentPattern = Join-Path $BufferDir "seg_%03d.ts"
    $wrapCount = [Math]::Max(8, [Math]::Ceiling(([double]$Config.ClipSeconds + 8) / [double]$Config.SegmentSeconds))
    $args = @("-hide_banner", "-loglevel", "warning", "-y", "-fflags", "+genpts")
    $args += Get-CaptureArguments -Config $Config
    if ($Audio.Enabled) {
        $args += $Audio.Arguments
    }
    $args += Get-VideoFilterArguments -Config $Config
    $args += @("-r", "$($Config.Fps)", "-fps_mode", "cfr")
    $args += Get-EncoderArguments -Encoder $Encoder -Config $Config
    $args += @("-map", "0:v:0")
    if ($Audio.Enabled) {
        $args += @("-map", "1:a:0", "-c:a", "aac", "-b:a", "$($Config.AudioBitrateKbps)k", "-ar", "48000", "-ac", "2", "-af", "aresample=async=1:first_pts=0")
    } else {
        $args += @("-an")
    }
    $args += @(
        "-force_key_frames", "expr:gte(t,n_forced*$($Config.SegmentSeconds))",
        "-f", "segment",
        "-segment_time", "$($Config.SegmentSeconds)",
        "-segment_wrap", "$wrapCount",
        "-reset_timestamps", "1",
        "-segment_format", "mpegts",
        $segmentPattern
    )
    return $args
}

function Start-Recorder {
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$Ffmpeg
    )

    Ensure-Directories -Config $Config
    Clear-Buffer

    $captures = @(Get-CaptureCandidates -Config $Config)
    $encoders = @(Get-EncoderCandidates -Config $Config -Ffmpeg $Ffmpeg)
    if (@($encoders).Count -eq 0) {
        throw "No usable H.264 encoder was reported by FFmpeg."
    }

    $errors = New-Object System.Collections.Generic.List[string]
    foreach ($capture in $captures) {
        foreach ($encoder in $encoders) {
            $attemptConfig = Copy-ConfigWith -Config $Config -Overrides @{ CaptureMode = $capture }
            foreach ($audioAttempt in (Get-AudioAttemptConfigs -Config $attemptConfig -Ffmpeg $Ffmpeg)) {
                $audioConfig = $audioAttempt.Config
                $audio = Get-AudioInputArguments -Config $audioConfig -Ffmpeg $Ffmpeg
                $arguments = Build-RecordArguments -Config $audioConfig -Encoder $encoder -Audio $audio

                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = $Ffmpeg
                $psi.Arguments = Join-ProcessArguments -Arguments $arguments
                $psi.WorkingDirectory = $AppRoot
                $psi.UseShellExecute = $false
                $psi.CreateNoWindow = $true
                $psi.RedirectStandardError = $true

                $process = [System.Diagnostics.Process]::Start($psi)
                Start-Sleep -Milliseconds 1300
                if (-not $process.HasExited) {
                    return [pscustomobject]@{
                        Process = $process
                        Encoder = $encoder
                        CaptureMode = $capture
                        AudioDevice = $audio.Device
                        AudioKind = $audio.Kind
                        AttemptWarnings = @($errors)
                        StartedAt = Get-Date
                    }
                }

                $err = $process.StandardError.ReadToEnd()
                $errors.Add("${capture}/${encoder}/$($audio.Kind): $err")
            }
        }
    }

    throw "Recorder failed to start with every capture/encoder fallback. $($errors -join ' | ')"
}

function Stop-Recorder {
    param($Recorder)
    if (-not $Recorder -or -not $Recorder.Process -or $Recorder.Process.HasExited) {
        return
    }

    try {
        $Recorder.Process.CloseMainWindow() | Out-Null
        Start-Sleep -Milliseconds 300
        if (-not $Recorder.Process.HasExited) {
            $Recorder.Process.Kill()
        }
        $Recorder.Process.WaitForExit(2000) | Out-Null
    } catch {
        try {
            $Recorder.Process.Kill()
            $Recorder.Process.WaitForExit(2000) | Out-Null
        } catch {}
    }
}

function Save-Clip {
    param(
        [Parameter(Mandatory)]$Config,
        [Parameter(Mandatory)][string]$Ffmpeg
    )

    Ensure-Directories -Config $Config
    $now = Get-Date
    $segmentsNeeded = [Math]::Ceiling(([double]$Config.ClipSeconds + [double]$Config.SegmentSeconds) / [double]$Config.SegmentSeconds)
    $segments = Get-ChildItem -LiteralPath $BufferDir -Filter "*.ts" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -gt 0 -and $_.LastWriteTime -lt $now.AddMilliseconds(-700) } |
        Sort-Object LastWriteTime |
        Select-Object -Last $segmentsNeeded

    if (-not $segments -or $segments.Count -eq 0) {
        throw "No completed video segments are ready yet."
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $listPath = Join-Path $BufferDir "concat_$stamp.txt"
    $outPath = Join-Path $Config.ClipDirectory "FortClip_$stamp.mp4"
    $lines = foreach ($segment in $segments) {
        "file '$($segment.FullName.Replace("'", "''"))'"
    }
    $lines | Set-Content -LiteralPath $listPath -Encoding ASCII

    $args = @("-hide_banner", "-loglevel", "warning", "-y", "-f", "concat", "-safe", "0", "-i", $listPath, "-c", "copy", "-movflags", "+faststart", $outPath)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Ffmpeg
    $psi.Arguments = Join-ProcessArguments -Arguments $args
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardError = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $p.WaitForExit()

    if ($p.ExitCode -ne 0) {
        $err = $p.StandardError.ReadToEnd()
        throw "Clip export failed: $err"
    }

    Remove-Item -LiteralPath $listPath -Force -ErrorAction SilentlyContinue
    return $outPath
}

function Convert-RatioToDouble {
    param([Parameter(Mandatory)][string]$Ratio)
    if ($Ratio -match "^(\d+)/(\d+)$" -and [double]$matches[2] -ne 0) {
        return [double]$matches[1] / [double]$matches[2]
    }
    return [double]$Ratio
}

function Test-ClipQuality {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)]$Config,
        [bool]$ExpectedAudio,
        [double]$ExpectedMinDurationSeconds = 0,
        [double]$ExpectedMaxDurationSeconds = 0,
        [switch]$RequireNoBFrames
    )

    $ffmpeg = Resolve-FfmpegPath -Config $Config
    $ffprobe = Resolve-FfprobePath -Ffmpeg $ffmpeg
    if (-not $ffprobe) {
        return [pscustomobject]@{
            Passed = $true
            Summary = "Saved clip. ffprobe not found, so quality check was skipped."
            Issues = @()
        }
    }

    $result = Invoke-ProcessCapture -FileName $ffprobe -Arguments @("-v", "error", "-count_packets", "-show_streams", "-show_format", "-of", "json", $Path) -TimeoutMilliseconds 30000
    if ($result.ExitCode -ne 0) {
        return [pscustomobject]@{
            Passed = $false
            Summary = "Saved clip, but ffprobe could not inspect it."
            Issues = @($result.StdErr.Trim())
        }
    }

    $info = $result.StdOut | ConvertFrom-Json
    $streams = @($info.streams)
    $formatDuration = 0.0
    if ($info.format -and $info.format.duration) {
        $formatDuration = [double]$info.format.duration
    }
    $video = $streams | Where-Object { $_.codec_type -eq "video" } | Select-Object -First 1
    $audio = $streams | Where-Object { $_.codec_type -eq "audio" } | Select-Object -First 1
    $issues = New-Object System.Collections.Generic.List[string]

    if (-not $video) {
        $issues.Add("missing video stream")
    } else {
        if ([int]$video.width -ne [int]$Config.Width -or [int]$video.height -ne [int]$Config.Height) {
            $issues.Add("expected $($Config.Width)x$($Config.Height), got $($video.width)x$($video.height)")
        }

        $fps = Convert-RatioToDouble -Ratio ([string]$video.avg_frame_rate)
        if ([Math]::Abs($fps - [double]$Config.Fps) -gt 0.5) {
            $issues.Add("expected $($Config.Fps) FPS, got $([Math]::Round($fps, 2)) FPS")
        }

        if ($RequireNoBFrames -and $video.PSObject.Properties.Name -contains "has_b_frames" -and [int]$video.has_b_frames -ne 0) {
            $issues.Add("expected no B-frames, got has_b_frames=$($video.has_b_frames)")
        }

        if ($ExpectedMinDurationSeconds -gt 0 -and $formatDuration -gt 0) {
            $expectedFrames = [Math]::Floor($ExpectedMinDurationSeconds * [double]$Config.Fps)
            if ($video.PSObject.Properties.Name -contains "nb_read_packets" -and $video.nb_read_packets -and [int]$video.nb_read_packets -lt ($expectedFrames - 2)) {
                $issues.Add("expected at least $expectedFrames video packets, got $($video.nb_read_packets)")
            }
        }
    }

    if ($ExpectedMinDurationSeconds -gt 0 -and $formatDuration -gt 0 -and $formatDuration -lt ($ExpectedMinDurationSeconds - 0.35)) {
        $issues.Add("expected duration >= $ExpectedMinDurationSeconds seconds, got $([Math]::Round($formatDuration, 2)) seconds")
    }

    if ($ExpectedMaxDurationSeconds -gt 0 -and $formatDuration -gt ($ExpectedMaxDurationSeconds + 0.75)) {
        $issues.Add("expected duration <= $ExpectedMaxDurationSeconds seconds, got $([Math]::Round($formatDuration, 2)) seconds")
    }

    if ($ExpectedAudio) {
        if (-not $audio) {
            $issues.Add("missing audio stream")
        } elseif ([int]$audio.sample_rate -ne 48000) {
            $issues.Add("expected 48000 Hz audio, got $($audio.sample_rate) Hz")
        }
    }

    $passed = $issues.Count -eq 0
    $summary = if ($passed) {
        $audioText = if ($audio) { "with audio" } else { "video only" }
        "Saved verified $($Config.Width)x$($Config.Height) $($Config.Fps) FPS clip $audioText."
    } else {
        "Saved clip, but quality check found: $($issues -join '; ')"
    }

    return [pscustomobject]@{
        Passed = $passed
        Summary = $summary
        Issues = @($issues)
        DurationSeconds = $formatDuration
    }
}

function Parse-Hotkey {
    param([Parameter(Mandatory)][string]$Text)

    $parts = $Text.Split("+", [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() }
    $mods = 0
    $keyText = $null

    foreach ($part in $parts) {
        switch -Regex ($part.ToLowerInvariant()) {
            "^(ctrl|control)$" { $mods = $mods -bor 0x0002; continue }
            "^alt$" { $mods = $mods -bor 0x0001; continue }
            "^shift$" { $mods = $mods -bor 0x0004; continue }
            "^(win|windows)$" { $mods = $mods -bor 0x0008; continue }
            default { $keyText = $part }
        }
    }

    if (-not $keyText) {
        throw "Hotkey needs a non-modifier key."
    }

    try {
        $key = [System.Windows.Input.Key]$keyText
    } catch {
        throw "Unsupported hotkey key '$keyText'."
    }

    $vk = [System.Windows.Input.KeyInterop]::VirtualKeyFromKey($key)
    if ($vk -le 0) {
        throw "Unsupported hotkey key '$keyText'."
    }

    return [pscustomobject]@{
        Modifiers = [uint32]$mods
        VirtualKey = [uint32]$vk
    }
}

function Format-Hotkey {
    param(
        [Parameter(Mandatory)][System.Windows.Input.Key]$Key,
        [Parameter(Mandatory)][System.Windows.Input.ModifierKeys]$Modifiers
    )

    $parts = New-Object System.Collections.Generic.List[string]
    if (($Modifiers -band [System.Windows.Input.ModifierKeys]::Control) -ne 0) { $parts.Add("Ctrl") }
    if (($Modifiers -band [System.Windows.Input.ModifierKeys]::Alt) -ne 0) { $parts.Add("Alt") }
    if (($Modifiers -band [System.Windows.Input.ModifierKeys]::Shift) -ne 0) { $parts.Add("Shift") }
    if (($Modifiers -band [System.Windows.Input.ModifierKeys]::Windows) -ne 0) { $parts.Add("Win") }
    $parts.Add($Key.ToString())
    return ($parts -join "+")
}

function Show-Toast {
    param(
        [Parameter(Mandatory)]$NotifyIcon,
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Message
    )
    $NotifyIcon.BalloonTipTitle = $Title
    $NotifyIcon.BalloonTipText = $Message
    $NotifyIcon.ShowBalloonTip(2500)
}

function Run-SelfTest {
    $config = Load-Config
    Ensure-Directories -Config $config
    $ffmpeg = Resolve-FfmpegPath -Config $config
    $encoder = Select-Encoder -Config $config -Ffmpeg $ffmpeg
    $audioDevices = @(Get-DshowAudioDevices -Ffmpeg $ffmpeg)
    $audioConfig = (@(Get-AudioAttemptConfigs -Config $config -Ffmpeg $ffmpeg)[0]).Config
    $audio = Get-AudioInputArguments -Config $audioConfig -Ffmpeg $ffmpeg
    $hotkey = Parse-Hotkey -Text $config.Hotkey
    [pscustomobject]@{
        AppRoot = $AppRoot
        Ffmpeg = $ffmpeg
        Encoder = $encoder
        AudioEnabled = $audio.Enabled
        AudioDevice = $audio.Device
        AudioKind = $audio.Kind
        AudioDevices = ($audioDevices -join "; ")
        Hotkey = $config.Hotkey
        HotkeyModifiers = $hotkey.Modifiers
        HotkeyVirtualKey = $hotkey.VirtualKey
        BufferDir = $BufferDir
        ClipDirectory = $config.ClipDirectory
    } | Format-List
}

function Run-CompatibilityReport {
    param([bool]$ProbeCapture)

    $config = Load-Config
    Ensure-Directories -Config $config
    $ffmpeg = Resolve-FfmpegPath -Config $config
    $ffprobe = Resolve-FfprobePath -Ffmpeg $ffmpeg
    $encoders = Get-EncoderCandidates -Config $config -Ffmpeg $ffmpeg
    $audioDevices = Get-DshowAudioDevices -Ffmpeg $ffmpeg
    $audioAttempts = @(Get-AudioAttemptConfigs -Config $config -Ffmpeg $ffmpeg | ForEach-Object {
        $audio = Get-AudioInputArguments -Config $_.Config -Ffmpeg $ffmpeg
        if ($audio.Device) { "$($audio.Kind): $($audio.Device)" } else { $audio.Kind }
    })
    $captures = Get-CaptureCandidates -Config $config
    $captureReport = if ($ProbeCapture) {
        @($captures | ForEach-Object { Test-CaptureCandidate -CaptureMode $_ -Config $config -Ffmpeg $ffmpeg })
    } else {
        @($captures | ForEach-Object {
            [pscustomobject]@{
                CaptureMode = $_
                Works = "not probed"
                Detail = "Run with -ProbeCapture from an interactive desktop session to test screen capture."
            }
        })
    }
    $audioReport = if ($ProbeCapture) {
        @($audioDevices | ForEach-Object { Test-AudioCandidate -AudioDevice $_ -Ffmpeg $ffmpeg })
    } else {
        @($audioDevices | ForEach-Object {
            [pscustomobject]@{
                AudioDevice = $_
                Works = "not probed"
                Detail = "Run with -ProbeCapture to test whether DirectShow audio can open."
            }
        })
    }

    [pscustomobject]@{
        Ffmpeg = $ffmpeg
        Ffprobe = $ffprobe
        Target = "$($config.Width)x$($config.Height)@$($config.Fps)"
        EncoderFallbackOrder = ($encoders -join " -> ")
        CaptureFallbackOrder = ($captures -join " -> ")
        AudioFallbackOrder = ($audioAttempts -join " -> ")
        DirectShowAudioDevices = if (@($audioDevices).Count -gt 0) { ($audioDevices -join "; ") } else { "none" }
    } | Format-List

    "Capture probe:"
    $captureReport | Format-Table -AutoSize
    ""
    "Audio probe:"
    if (@($audioReport).Count -gt 0) {
        $audioReport | Format-Table -AutoSize
    } else {
        "No DirectShow audio devices were found. Auto mode can still use silent AAC fallback."
    }
}

function Run-SmokeTest {
    param(
        [int]$DurationSeconds,
        [bool]$KeepClip,
        [string]$CaptureMode = "",
        [string]$Encoder = "",
        [string]$AudioMode = ""
    )

    $config = Load-Config
    Ensure-Directories -Config $config
    $ffmpeg = Resolve-FfmpegPath -Config $config

    $testSeconds = [Math]::Max(6, $DurationSeconds)
    $clipSeconds = [Math]::Max(4, $testSeconds - [int]$config.SegmentSeconds)
    $overrides = @{
        Enabled = $false
        ClipSeconds = $clipSeconds
    }
    if ($CaptureMode) {
        $overrides.CaptureMode = $CaptureMode
    }
    if ($Encoder) {
        $overrides.Encoder = $Encoder
    }
    if ($AudioMode) {
        $overrides.AudioMode = $AudioMode
        $overrides.AudioDevice = ""
    }
    $testConfig = Copy-ConfigWith -Config $config -Overrides $overrides

    $recorder = $null
    $clipPath = ""
    try {
        $recorder = Start-Recorder -Config $testConfig -Ffmpeg $ffmpeg
        Start-Sleep -Seconds $testSeconds
        $clipPath = Save-Clip -Config $testConfig -Ffmpeg $ffmpeg
        $quality = Test-ClipQuality -Path $clipPath -Config $testConfig -ExpectedAudio ([bool]$recorder.AudioDevice) -ExpectedMinDurationSeconds ([Math]::Max(2, $clipSeconds - [int]$testConfig.SegmentSeconds)) -ExpectedMaxDurationSeconds ($clipSeconds + ([int]$testConfig.SegmentSeconds * 2)) -RequireNoBFrames

        [pscustomobject]@{
            Passed = $quality.Passed
            Clip = $clipPath
            CaptureMode = $recorder.CaptureMode
            Encoder = $recorder.Encoder
            AudioKind = $recorder.AudioKind
            AudioDevice = $recorder.AudioDevice
            DurationSeconds = [Math]::Round($quality.DurationSeconds, 2)
            Summary = $quality.Summary
            Issues = ($quality.Issues -join "; ")
            FallbackWarnings = ($recorder.AttemptWarnings -join " | ")
        } | Format-List

        if (-not $quality.Passed) {
            exit 1
        }
    } finally {
        Stop-Recorder -Recorder $recorder
        if ($clipPath -and -not $KeepClip -and (Test-Path -LiteralPath $clipPath)) {
            Remove-Item -LiteralPath $clipPath -Force -ErrorAction SilentlyContinue
        }
        Clear-Buffer
    }
}

if ($ListAudioDevices) {
    $config = Load-Config
    $ffmpeg = Resolve-FfmpegPath -Config $config
    Get-DshowAudioDevices -Ffmpeg $ffmpeg
    return
}

if ($CompatibilityReport) {
    Run-CompatibilityReport -ProbeCapture ([bool]$ProbeCapture)
    return
}

if ($SmokeTest) {
    Run-SmokeTest -DurationSeconds $SmokeSeconds -KeepClip ([bool]$KeepSmokeClip) -CaptureMode $SmokeCaptureMode -Encoder $SmokeEncoder -AudioMode $SmokeAudioMode
    return
}

if ($SelfTest) {
    Run-SelfTest
    return
}

$Config = Load-Config
Ensure-Directories -Config $Config
$FfmpegPath = Resolve-FfmpegPath -Config $Config
$Recorder = $null
$HotkeyId = 7101
$CapturingHotkey = $false

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="FortClipLite" Width="420" Height="500" ResizeMode="NoResize"
        WindowStartupLocation="CenterScreen" Background="#101214">
    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,18">
            <TextBlock Text="FortClipLite" Foreground="#F3F5F7" FontSize="24" FontWeight="SemiBold"/>
            <TextBlock x:Name="StatusText" Text="Idle" Foreground="#9AA3AD" FontSize="13" Margin="0,4,0,0"/>
        </StackPanel>

        <Button x:Name="ToggleButton" Grid.Row="1" Height="46" Margin="0,0,0,16"
                Background="#2D7D46" Foreground="White" BorderThickness="0"
                FontSize="16" FontWeight="SemiBold" Content="Start Capture"/>

        <Grid Grid.Row="2" Margin="0,0,0,16">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="12"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0">
                <TextBlock Text="Clip Length" Foreground="#C8D0D8" Margin="0,0,0,6"/>
                <ComboBox x:Name="ClipSecondsBox" Height="30">
                    <ComboBoxItem Content="15"/>
                    <ComboBoxItem Content="30"/>
                    <ComboBoxItem Content="45"/>
                    <ComboBoxItem Content="60"/>
                    <ComboBoxItem Content="90"/>
                </ComboBox>
            </StackPanel>
            <StackPanel Grid.Column="2">
                <TextBlock Text="Bitrate Mbps" Foreground="#C8D0D8" Margin="0,0,0,6"/>
                <ComboBox x:Name="BitrateBox" Height="30">
                    <ComboBoxItem Content="20"/>
                    <ComboBoxItem Content="35"/>
                    <ComboBoxItem Content="50"/>
                    <ComboBoxItem Content="65"/>
                </ComboBox>
            </StackPanel>
        </Grid>

        <StackPanel Grid.Row="3">
            <TextBlock Text="Clip Hotkey" Foreground="#C8D0D8" Margin="0,0,0,6"/>
            <Button x:Name="HotkeyButton" Height="34" Background="#22272D" Foreground="#F3F5F7" BorderBrush="#39414A"/>

            <TextBlock Text="Encoder" Foreground="#C8D0D8" Margin="0,14,0,6"/>
            <ComboBox x:Name="EncoderBox" Height="30">
                <ComboBoxItem Content="auto"/>
                <ComboBoxItem Content="h264_nvenc"/>
                <ComboBoxItem Content="h264_amf"/>
                <ComboBoxItem Content="h264_qsv"/>
                <ComboBoxItem Content="h264_mf"/>
                <ComboBoxItem Content="libx264"/>
            </ComboBox>

            <TextBlock Text="Audio" Foreground="#C8D0D8" Margin="0,14,0,6"/>
            <ComboBox x:Name="AudioBox" Height="30"/>

            <CheckBox x:Name="MouseBox" Content="Capture cursor" Foreground="#C8D0D8" Margin="0,14,0,0"/>
            <Button x:Name="FolderButton" Height="32" Margin="0,14,0,0" Background="#22272D" Foreground="#F3F5F7" BorderBrush="#39414A" Content="Open Clips Folder"/>
        </StackPanel>

        <TextBlock Grid.Row="4" x:Name="FooterText" Foreground="#747F8B" FontSize="12" TextWrapping="Wrap"/>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)

$StatusText = $Window.FindName("StatusText")
$ToggleButton = $Window.FindName("ToggleButton")
$ClipSecondsBox = $Window.FindName("ClipSecondsBox")
$BitrateBox = $Window.FindName("BitrateBox")
$HotkeyButton = $Window.FindName("HotkeyButton")
$EncoderBox = $Window.FindName("EncoderBox")
$AudioBox = $Window.FindName("AudioBox")
$MouseBox = $Window.FindName("MouseBox")
$FolderButton = $Window.FindName("FolderButton")
$FooterText = $Window.FindName("FooterText")

$ClipSecondsBox.Text = [string]$Config.ClipSeconds
$BitrateBox.Text = [string]$Config.BitrateMbps
$HotkeyButton.Content = $Config.Hotkey
$EncoderBox.Text = $Config.Encoder
$AudioBox.Items.Add("auto") | Out-Null
$AudioBox.Items.Add("silent") | Out-Null
$AudioBox.Items.Add("disabled") | Out-Null
foreach ($device in (Get-DshowAudioDevices -Ffmpeg $FfmpegPath)) {
    $AudioBox.Items.Add($device) | Out-Null
}
if ($Config.AudioMode -eq "disabled") {
    $AudioBox.Text = "disabled"
} elseif ($Config.AudioMode -eq "silent") {
    $AudioBox.Text = "silent"
} elseif ($Config.AudioDevice) {
    $AudioBox.Text = [string]$Config.AudioDevice
} else {
    $AudioBox.Text = "auto"
}
$MouseBox.IsChecked = [bool]$Config.IncludeMouse
$FooterText.Text = "Close hides to tray. Saved clips: $($Config.ClipDirectory)"

$NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$NotifyIcon.Icon = [System.Drawing.SystemIcons]::Application
$NotifyIcon.Text = "FortClipLite"
$NotifyIcon.Visible = $true
$NotifyMenu = New-Object System.Windows.Forms.ContextMenuStrip
$ShowItem = $NotifyMenu.Items.Add("Show")
$ClipItem = $NotifyMenu.Items.Add("Save clip")
$ExitItem = $NotifyMenu.Items.Add("Exit")
$NotifyIcon.ContextMenuStrip = $NotifyMenu

function Sync-UiFromState {
    if ($Recorder -and -not $Recorder.Process.HasExited) {
        $ToggleButton.Content = "Stop Capture"
        $ToggleButton.Background = "#9C3D34"
        $audioLabel = if ($Recorder.AudioDevice) { " + $($Recorder.AudioDevice)" } else { " video only" }
        $StatusText.Text = "Recording $($Config.Width)x$($Config.Height) $($Config.Fps) FPS via $($Recorder.CaptureMode)/$($Recorder.Encoder)$audioLabel"
    } else {
        $ToggleButton.Content = "Start Capture"
        $ToggleButton.Background = "#2D7D46"
        $StatusText.Text = "Idle"
    }
}

function Sync-ConfigFromUi {
    $Config.ClipSeconds = [int]$ClipSecondsBox.Text
    $Config.BitrateMbps = [int]$BitrateBox.Text
    $Config.Hotkey = [string]$HotkeyButton.Content
    $Config.Encoder = [string]$EncoderBox.Text
    $audioSelection = [string]$AudioBox.Text
    if ($audioSelection -eq "disabled") {
        $Config.AudioMode = "disabled"
        $Config.AudioDevice = ""
    } elseif ($audioSelection -eq "silent") {
        $Config.AudioMode = "silent"
        $Config.AudioDevice = ""
    } elseif ($audioSelection -eq "auto" -or -not $audioSelection) {
        $Config.AudioMode = "auto"
        $Config.AudioDevice = ""
    } else {
        $Config.AudioMode = "dshow"
        $Config.AudioDevice = $audioSelection
    }
    $Config.IncludeMouse = [bool]$MouseBox.IsChecked
    Save-Config -Config $Config
}

function Register-CurrentHotkey {
    param([Parameter(Mandatory)][intptr]$Handle)
    [NativeHotKey]::UnregisterHotKey($Handle, $HotkeyId) | Out-Null
    $parsed = Parse-Hotkey -Text $Config.Hotkey
    if (-not [NativeHotKey]::RegisterHotKey($Handle, $HotkeyId, $parsed.Modifiers, $parsed.VirtualKey)) {
        throw "Could not register global hotkey '$($Config.Hotkey)'. It may be in use by another app."
    }
}

function Toggle-Capture {
    try {
        Sync-ConfigFromUi
        if ($Recorder -and -not $Recorder.Process.HasExited) {
            Stop-Recorder -Recorder $Recorder
            $script:Recorder = $null
            $Config.Enabled = $false
            Save-Config -Config $Config
            Show-Toast -NotifyIcon $NotifyIcon -Title $AppName -Message "Capture stopped."
        } else {
            $script:Recorder = Start-Recorder -Config $Config -Ffmpeg $FfmpegPath
            $Config.Enabled = $true
            Save-Config -Config $Config
            Show-Toast -NotifyIcon $NotifyIcon -Title $AppName -Message "Capture is running in the background."
        }
    } catch {
        [System.Windows.MessageBox]::Show($_.Exception.Message, $AppName, "OK", "Error") | Out-Null
    } finally {
        Sync-UiFromState
    }
}

function Trigger-Clip {
    try {
        if (-not $Recorder -or $Recorder.Process.HasExited) {
            Show-Toast -NotifyIcon $NotifyIcon -Title $AppName -Message "Capture is not running."
            return
        }
        $path = Save-Clip -Config $Config -Ffmpeg $FfmpegPath
        $quality = Test-ClipQuality -Path $path -Config $Config -ExpectedAudio ([bool]$Recorder.AudioDevice)
        Show-Toast -NotifyIcon $NotifyIcon -Title $AppName -Message $quality.Summary
    } catch {
        Show-Toast -NotifyIcon $NotifyIcon -Title $AppName -Message $_.Exception.Message
    }
}

$ToggleButton.Add_Click({ Toggle-Capture })
$ClipItem.Add_Click({ Trigger-Clip })
$ShowItem.Add_Click({ $Window.Show(); $Window.Activate() | Out-Null })
$NotifyIcon.Add_DoubleClick({ $Window.Show(); $Window.Activate() | Out-Null })
$FolderButton.Add_Click({
    Sync-ConfigFromUi
    Start-Process explorer.exe -ArgumentList "`"$($Config.ClipDirectory)`""
})
$ExitItem.Add_Click({
    Stop-Recorder -Recorder $Recorder
    $NotifyIcon.Visible = $false
    [System.Windows.Application]::Current.Shutdown()
})

$HotkeyButton.Add_Click({
    $script:CapturingHotkey = $true
    $HotkeyButton.Content = "Press keys..."
    $HotkeyButton.Focus() | Out-Null
})

$Window.Add_KeyDown({
    param($sender, $eventArgs)
    if (-not $script:CapturingHotkey) {
        return
    }

    $key = $eventArgs.Key
    if ($key -eq [System.Windows.Input.Key]::System) {
        $key = $eventArgs.SystemKey
    }
    if ($key -eq [System.Windows.Input.Key]::LeftCtrl -or
        $key -eq [System.Windows.Input.Key]::RightCtrl -or
        $key -eq [System.Windows.Input.Key]::LeftAlt -or
        $key -eq [System.Windows.Input.Key]::RightAlt -or
        $key -eq [System.Windows.Input.Key]::LeftShift -or
        $key -eq [System.Windows.Input.Key]::RightShift -or
        $key -eq [System.Windows.Input.Key]::LWin -or
        $key -eq [System.Windows.Input.Key]::RWin) {
        return
    }

    $mods = [System.Windows.Input.Keyboard]::Modifiers
    $HotkeyButton.Content = Format-Hotkey -Key $key -Modifiers $mods
    $script:CapturingHotkey = $false
    Sync-ConfigFromUi
    try {
        $helper = New-Object System.Windows.Interop.WindowInteropHelper($Window)
        Register-CurrentHotkey -Handle $helper.Handle
    } catch {
        [System.Windows.MessageBox]::Show($_.Exception.Message, $AppName, "OK", "Error") | Out-Null
    }
    $eventArgs.Handled = $true
})

$Window.Add_Closing({
    param($sender, $eventArgs)
    $eventArgs.Cancel = $true
    $Window.Hide()
    if ($Recorder -and -not $Recorder.Process.HasExited) {
        Show-Toast -NotifyIcon $NotifyIcon -Title $AppName -Message "Still recording. Use the tray icon to reopen or exit."
    }
})

$Window.Add_SourceInitialized({
    $helper = New-Object System.Windows.Interop.WindowInteropHelper($Window)
    Register-CurrentHotkey -Handle $helper.Handle
    $source = [System.Windows.Interop.HwndSource]::FromHwnd($helper.Handle)
    $source.AddHook({
        param($hwnd, $msg, $wParam, $lParam, [ref]$handled)
        if ($msg -eq 0x0312 -and $wParam.ToInt32() -eq $HotkeyId) {
            Trigger-Clip
            $handled.Value = $true
        }
        return [intptr]::Zero
    })

    if ($Config.Enabled) {
        Toggle-Capture
    } else {
        Sync-UiFromState
    }
})

$app = New-Object System.Windows.Application
[void]$app.Run($Window)
