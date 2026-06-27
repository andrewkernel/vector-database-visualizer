# Architecture

FortClipLite is intentionally small:

1. WPF UI hosted by Windows PowerShell.
2. `RegisterHotKey` for a global save-clip shortcut.
3. FFmpeg capture process kept alive in the background.
4. Rolling MPEG-TS segment buffer on disk.
5. Fast clip save via concat remux to MP4.

## Capture Backend

Default auto path:

```text
ddagrab -> hwdownload -> fast scale to 1080p -> hardware H.264 encoder -> segment muxer
```

Fallback:

```text
gdigrab -> CPU scale -> hardware/software H.264 encoder -> segment muxer
```

Audio path:

```text
DirectShow audio input -> AAC 160 kbps -> 48 kHz stereo -> segment muxer
```

Audio fallback:

```text
silent stereo anullsrc -> AAC 160 kbps -> 48 kHz stereo -> segment muxer
```

Auto mode tries Desktop Duplication before GDI capture, and tries NVENC, AMF, Quick Sync, Media Foundation, then x264. For audio, it tries DirectShow first, silent AAC second, and video-only last. This lets the same app run on NVIDIA, AMD, Intel, integrated-only, CPU-only, and awkward-audio systems, with hardware acceleration used when it actually starts successfully.

This avoids raw frame buffering in the app and keeps the PowerShell host out of the hot video path.

## Why Not Hook Fortnite?

Hook-based game capture can be fast, but it touches the game process and can trip anti-cheat systems. A consumer clipping tool should stay outside the game process unless it has explicit vendor integration.

## Next Native Upgrade Path

The next performance step is replacing the FFmpeg process wrapper with a small C++ service:

- Windows Graphics Capture or Desktop Duplication
- Direct3D 11 texture ring
- Media Foundation or vendor SDK H.264 encoder
- lock-free encoded packet ring
- tiny named-pipe control surface for the UI

The user-facing UI and settings in this prototype can remain the control layer while the recorder backend is swapped underneath.
