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
