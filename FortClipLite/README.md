# FortClipLite

FortClipLite is a minimal Windows clipping app aimed at low overhead Fortnite recording:

- 1080p, 60 FPS rolling capture
- global configurable clip hotkey
- one-button start/stop
- close-to-tray background behavior
- hardware H.264 encoder preference: NVENC, AMF, Quick Sync, Media Foundation, then x264 fallback
- DirectShow audio capture with AAC 48 kHz stereo output
- automatic capture/encoder fallback for wider PC compatibility
- silent AAC fallback when no real audio input can start
- disk-backed rolling segment buffer so RAM usage stays flat
- saved-clip validation for resolution, FPS, and audio stream presence
- end-to-end smoke test mode that records, saves, and validates a real MP4

## Run

Double-click `Start-FortClipLite.bat`.

The default clip hotkey is `Ctrl+Alt+F10`. Closing the window hides it to the tray; use the tray menu to show, save a clip, or exit.

FortClipLite looks for FFmpeg in this order: `config.json`, `FortClipLite/bin/ffmpeg.exe`, PATH, then common WinGet FFmpeg package folders.

If FFmpeg is missing, run `Setup-FFmpeg.bat`. It detects local/WinGet FFmpeg installs and updates `config.json`. For a portable install, put `ffmpeg.exe` and `ffprobe.exe` in `FortClipLite/bin`. To install through WinGet, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Setup-FFmpeg.ps1 -InstallWithWinget
```

Use the Audio selector to choose `auto`, `silent`, `disabled`, or a specific DirectShow audio device. If you want game/system audio, select a loopback device such as Stereo Mix, a capture-card audio device, or a virtual cable if your PC exposes one. In auto mode, FortClipLite tries real DirectShow audio first, a silent AAC track second, and video-only last so the recorder still starts on difficult PCs.

Run `Run-CompatibilityReport.bat` on a PC before benchmarking. It prints the exact FFmpeg path, usable encoders, available audio devices, fallback order, and whether Desktop Duplication / GDI capture can grab a frame from the current desktop session.

For the strongest one-command check, run `Run-ValidationSuite.bat`. It runs:

- compatibility probe
- default hardware-preferred smoke test
- forced CPU-only fallback smoke test

It writes timestamped Markdown and JSON reports into `FortClipLite/reports`.

For a stronger local check, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\FortClipLite.ps1 -SmokeTest -SmokeSeconds 8 -KeepSmokeClip
```

That starts the background recorder, writes rolling segments, exports a clip, and validates the final MP4 for resolution, FPS, video packet count, audio, duration, and B-frame settings.
You can also double-click `Run-SmokeTest.bat`.

To prove the CPU-only fallback path on a PC, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\FortClipLite.ps1 -SmokeTest -SmokeSeconds 8 -SmokeCaptureMode gdigrab -SmokeEncoder libx264 -SmokeAudioMode silent -KeepSmokeClip
```

You can also double-click `Run-CPUFallbackSmokeTest.bat`. This forces GDI screen capture, CPU H.264 encoding, and a silent AAC track. It is intentionally the least fancy path and is useful for checking machines without a usable hardware encoder.

## Design Notes

Fortnite uses anti-cheat, so this app avoids process injection and game hooks. The default backend uses FFmpeg's Desktop Duplication (`ddagrab`) plus hardware encode where possible. That is safer and lighter than a CPU-only GDI capture path, and it avoids touching the game process.

The app continuously writes short `.ts` segments into `FortClipLite/buffer`. When you press the hotkey, it remuxes the latest completed segments into an `.mp4` in `FortClipLite/clips`. This keeps clip creation fast because frames are not re-encoded when saving. After saving, it uses `ffprobe` to verify the clip is 1080p, 60 FPS, and includes audio when the active recorder had an audio input.

## Settings

Settings are saved in `config.json` after the first run. Useful fields:

- `ClipSeconds`: seconds to keep for each saved clip
- `BitrateMbps`: target video bitrate
- `Encoder`: `auto`, `h264_nvenc`, `h264_amf`, `h264_qsv`, `h264_mf`, or `libx264`
- `CaptureMode`: `auto`, `ddagrab`, or `gdigrab`
- `DisplayIndex`: monitor index for Desktop Duplication
- `AudioMode`: `auto`, `silent`, `disabled`, or `dshow`
- `AudioDevice`: DirectShow audio device name or stable alternative name; blank means first available in auto mode
- `AudioFallback`: `silent` keeps an AAC stream even when real audio cannot start
- `AudioBitrateKbps`: AAC audio bitrate
- `Hotkey`: global save-clip shortcut
- `ClipDirectory`: output folder
- `FfmpegPath`: optional explicit path to `ffmpeg.exe`

## Clip Validation

You can inspect any generated clip manually:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Test-ClipQuality.ps1 -ClipPath .\clips\FortClip_YYYYMMDD_HHMMSS.mp4 -RequireAudio
```

The checker fails if the video is not 1920x1080, the average frame rate is not within 0.5 FPS of 60, or required audio is missing.

## Compatibility Report

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\FortClipLite.ps1 -CompatibilityReport -ProbeCapture
```

Use this on every target PC. A healthy report should show at least one working capture mode, at least one encoder, and either a DirectShow audio device or the silent audio fallback.

## Benchmarking

For a fair ShadowPlay comparison:

1. Use the same resolution, frame rate, bitrate, and clip length.
2. Test in the same Fortnite replay or creative map.
3. Record CPU, GPU video encode, GPU 3D, RAM, and 1% low FPS.
4. Compare three passes: no recorder, ShadowPlay, FortClipLite.

FortClipLite should be most competitive when `ddagrab` and a hardware encoder are active. If it falls back to `gdigrab` or `libx264`, CPU usage will rise, but it should still record on machines without a working hardware encoder.
