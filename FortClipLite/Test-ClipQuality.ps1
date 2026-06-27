param(
    [Parameter(Mandatory)][string]$ClipPath,
    [int]$ExpectedWidth = 1920,
    [int]$ExpectedHeight = 1080,
    [double]$ExpectedFps = 60,
    [switch]$RequireAudio,
    [double]$ExpectedMinDurationSeconds = 0,
    [double]$ExpectedMaxDurationSeconds = 0,
    [switch]$RequireNoBFrames
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-FfprobePath {
    $local = Join-Path $AppRoot "bin\ffprobe.exe"
    if (Test-Path -LiteralPath $local) {
        return (Resolve-Path -LiteralPath $local).Path
    }

    $cmd = Get-Command ffprobe.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $wingetRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path -LiteralPath $wingetRoot) {
        $candidate = Get-ChildItem -LiteralPath $wingetRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*FFmpeg*" } |
            ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Recurse -Filter "ffprobe.exe" -File -ErrorAction SilentlyContinue } |
            Select-Object -First 1
        if ($candidate) {
            return $candidate.FullName
        }
    }

    throw "ffprobe.exe was not found. Put it in FortClipLite\bin, add it to PATH, or install FFmpeg with ffprobe."
}

function Convert-RatioToDouble {
    param([Parameter(Mandatory)][string]$Ratio)
    if ($Ratio -match "^(\d+)/(\d+)$" -and [double]$matches[2] -ne 0) {
        return [double]$matches[1] / [double]$matches[2]
    }
    return [double]$Ratio
}

$clip = Resolve-Path -LiteralPath $ClipPath
$ffprobe = Resolve-FfprobePath
$json = & $ffprobe -v error -count_packets -show_streams -show_format -of json $clip.Path
$info = $json | ConvertFrom-Json
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
    if ([int]$video.width -ne $ExpectedWidth -or [int]$video.height -ne $ExpectedHeight) {
        $issues.Add("expected ${ExpectedWidth}x${ExpectedHeight}, got $($video.width)x$($video.height)")
    }
    $fps = Convert-RatioToDouble -Ratio ([string]$video.avg_frame_rate)
    if ([Math]::Abs($fps - $ExpectedFps) -gt 0.5) {
        $issues.Add("expected $ExpectedFps FPS, got $([Math]::Round($fps, 2)) FPS")
    }
    if ($RequireNoBFrames -and $video.PSObject.Properties.Name -contains "has_b_frames" -and [int]$video.has_b_frames -ne 0) {
        $issues.Add("expected no B-frames, got has_b_frames=$($video.has_b_frames)")
    }
    if ($ExpectedMinDurationSeconds -gt 0 -and $video.PSObject.Properties.Name -contains "nb_read_packets" -and $video.nb_read_packets) {
        $expectedFrames = [Math]::Floor($ExpectedMinDurationSeconds * $ExpectedFps)
        if ([int]$video.nb_read_packets -lt ($expectedFrames - 2)) {
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

if ($RequireAudio) {
    if (-not $audio) {
        $issues.Add("missing audio stream")
    } elseif ([int]$audio.sample_rate -ne 48000) {
        $issues.Add("expected 48000 Hz audio, got $($audio.sample_rate) Hz")
    }
}

if ($issues.Count -gt 0) {
    $issues | ForEach-Object { Write-Error $_ }
    exit 1
}

[pscustomobject]@{
    Clip = $clip.Path
    Width = [int]$video.width
    Height = [int]$video.height
    Fps = Convert-RatioToDouble -Ratio ([string]$video.avg_frame_rate)
    VideoCodec = [string]$video.codec_name
    DurationSeconds = [Math]::Round($formatDuration, 3)
    VideoPackets = if ($video.PSObject.Properties.Name -contains "nb_read_packets" -and $video.nb_read_packets) { [int]$video.nb_read_packets } else { 0 }
    HasBFrames = if ($video.PSObject.Properties.Name -contains "has_b_frames") { [int]$video.has_b_frames } else { 0 }
    HasAudio = [bool]$audio
    AudioCodec = if ($audio) { [string]$audio.codec_name } else { "" }
    AudioSampleRate = if ($audio) { [int]$audio.sample_rate } else { 0 }
} | Format-List
