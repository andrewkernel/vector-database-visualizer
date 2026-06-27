param(
    [switch]$InstallWithWinget
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $AppRoot "config.json"

function Find-LocalFfmpeg {
    $local = Join-Path $AppRoot "bin\ffmpeg.exe"
    if (Test-Path -LiteralPath $local) {
        return (Resolve-Path -LiteralPath $local).Path
    }

    $cmd = Get-Command ffmpeg.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $wingetRoot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path -LiteralPath $wingetRoot) {
        $candidate = Get-ChildItem -LiteralPath $wingetRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*FFmpeg*" } |
            ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Recurse -Filter "ffmpeg.exe" -File -ErrorAction SilentlyContinue } |
            Select-Object -First 1
        if ($candidate) {
            return $candidate.FullName
        }
    }

    return ""
}

function Update-ConfigFfmpeg {
    param([Parameter(Mandatory)][string]$FfmpegPath)

    if (Test-Path -LiteralPath $ConfigPath) {
        $config = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
    } else {
        $config = Get-Content -Raw -LiteralPath (Join-Path $AppRoot "config.example.json") | ConvertFrom-Json
    }

    $config.FfmpegPath = $FfmpegPath
    $config | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ConfigPath -Encoding UTF8
}

$ffmpeg = Find-LocalFfmpeg
if ($ffmpeg) {
    Update-ConfigFfmpeg -FfmpegPath $ffmpeg
    Write-Host "FFmpeg found:"
    Write-Host $ffmpeg
    Write-Host "config.json updated."
    exit 0
}

if (-not $InstallWithWinget) {
    Write-Host "FFmpeg was not found."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "1. Put ffmpeg.exe and ffprobe.exe in FortClipLite\bin"
    Write-Host "2. Add FFmpeg to PATH"
    Write-Host "3. Run this script with -InstallWithWinget"
    exit 1
}

$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    throw "winget.exe was not found. Install FFmpeg manually or place ffmpeg.exe and ffprobe.exe in FortClipLite\bin."
}

& winget.exe install --id Gyan.FFmpeg.Shared --exact --silent --accept-package-agreements --accept-source-agreements

$ffmpeg = Find-LocalFfmpeg
if (-not $ffmpeg) {
    throw "FFmpeg install finished, but ffmpeg.exe was still not found."
}

Update-ConfigFfmpeg -FfmpegPath $ffmpeg
Write-Host "FFmpeg installed/found:"
Write-Host $ffmpeg
Write-Host "config.json updated."

