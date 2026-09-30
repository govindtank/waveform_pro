## 1.1.2

* Pinned documentation preview image to version tag to bypass CDN cache.

## 1.1.1

* Updated documentation with high-resolution SVG visual overview banner.

## 1.1.0

* Added `WaveformRenderMode` support:
  * `WaveformRenderMode.continuous`: classic mirrored continuous envelope path.
  * `WaveformRenderMode.bars`: discrete rounded vertical bars (SoundCloud / Voice Memos style) with configurable `barWidth`, `barSpacing`, and `barRadius`.
  * `WaveformRenderMode.curvedSpline`: sleek cubic bezier spline curve envelope.
* Added dual-color playback progress shader (`playedWaveColor` vs `waveColor`) reflecting current `playheadPosition`.
* Added `WaveformData.append(...)` helper for dynamic / real-time streaming audio buffers.
* Added `WaveformExporter.toPngBytes(...)` for headless waveform thumbnail and preview image generation without widget mounting.
* Added curated style presets: `WaveformStyle.voiceMemo` and `WaveformStyle.neonGlow`.
* Added comprehensive unit, widget, and PNG export tests.

## 1.0.3

* Added `platforms` declaration (android, ios, linux, macos, windows, web).

## 1.0.2

* Exclude IDE files (`.idea/`, `*.iml`) from the published archive.

## 1.0.1

* Initial public release cleanup: archive now excludes build and IDE artifacts.

## 1.0.0

* Initial release as a production-quality Flutter waveform widget.
* GPU-accelerated waveform rendering via a custom `CustomPainter` (no external audio libs).
* Audio peak extraction (`WaveformPeakExtractor`) from WAV / PCM data.
* Zoom + pan timeline with interactive region selection.
* Cue markers, playhead, and a `WaveformController` API for programmatic control.
* Dark/light theme support via configurable painter styles.

## 1.1.3

* Fix example analysis issue on pub.dev by updating .pubignore.
* Improve pub.dev compatibility.
