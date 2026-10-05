# waveform_pro

[![Pub Version](https://img.shields.io/pub/v/waveform_pro.svg?style=flat-square&color=blue)](https://pub.dev/packages/waveform_pro)
[![Pub Points](https://img.shields.io/pub/points/waveform_pro?style=flat-square&color=2E8B57&label=pub%20points)](https://pub.dev/packages/waveform_pro/score)
[![Pub Likes](https://img.shields.io/pub/likes/waveform_pro?style=flat-square)](https://pub.dev/packages/waveform_pro)
[![CI](https://github.com/govindtank/waveform_pro/actions/workflows/ci.yml/badge.svg)](https://github.com/govindtank/waveform_pro/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue?style=flat-square)](https://pub.dev/packages/waveform_pro)

A production-quality, GPU-accelerated Flutter audio waveform visualization library supporting continuous envelopes, discrete SoundCloud-style bars, bezier curved splines, dual-color playback progress, interactive zooming/panning, draggable region selection, cue markers, live audio stream buffering, and headless PNG exports.

Now available on **[pub.dev/packages/waveform_pro](https://pub.dev/packages/waveform_pro)**.

---

<p align="center">
  <img src="https://raw.githubusercontent.com/govindtank/waveform_pro/v1.1.1/screenshot.svg" width="680" alt="waveform_pro screenshot" />
</p>

---

## ✨ Features

- 📊 **Multiple Render Modes**:
  - `WaveformRenderMode.continuous` — Classic mirrored continuous path.
  - `WaveformRenderMode.bars` — Discrete rounded vertical bars (SoundCloud & Apple Voice Memos style).
  - `WaveformRenderMode.curvedSpline` — Ultra-smooth cubic bezier spline curves.
- ⏯️ **Dual-Color Playback Progress** — Colorize played vs unplayed waveform segments (`playedWaveColor` vs `waveColor`) based on `playheadPosition`.
- ⚡ **Multi-Resolution Pyramid Caching** — Decimates waveform data at powers-of-two for 60fps rendering across any zoom level.
- 🔍 **Interactive Timeline** — Pinch-to-zoom, horizontal drag/pan, and programmatic `WaveformController` with automatic viewport adaptation.
- 📍 **Regions & Cue Markers** — Interactive region selection with draggable bounds and labeled cue bookmarks.
- 🎙️ **Live Audio Buffer Support** — Dynamically append audio peaks to `WaveformData` (`data.append(...)`) for real-time recorders.
- 🖼️ **Headless PNG Image Exporter** — Generate waveform images directly to `Uint8List` via `WaveformExporter.toPngBytes(...)` without mounting widgets.
- 🎨 **Built-in Presets** — Ready-to-use themes like `WaveformStyle.voiceMemo` and `WaveformStyle.neonGlow`.

---

## 📦 Installation

Add `waveform_pro` to your Flutter project:

```bash
flutter pub add waveform_pro
```

Or add it to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  waveform_pro: ^1.1.4
```

Import:

```dart
import 'package:waveform_pro/waveform_pro.dart';
```

---

## 🚀 Usage

### 1. Basic Waveform Timeline (SoundCloud / Voice Memos Bar Style)

```dart
import 'package:flutter/material.dart';
import 'package:waveform_pro/waveform_pro.dart';

class AudioPlayerWaveform extends StatelessWidget {
  final WaveformData waveformData;

  const AudioPlayerWaveform({super.key, required this.waveformData});

  @override
  Widget build(BuildContext context) {
    return WaveformTimeline(
      data: waveformData,
      style: WaveformStyle.voiceMemo,
      playheadPosition: 12.4, // seconds played
      playheadColor: Colors.blueAccent,
      showTimeRuler: true,
      onTap: (seconds) {
        print('User seeked to: ${seconds}s');
      },
      onRegionChanged: (start, end) {
        print('Selected region: $start - $end');
      },
    );
  }
}
```

---

### 2. Smooth Curved Spline Mode

```dart
WaveformTimeline(
  data: waveformData,
  style: WaveformStyle.neonGlow,
  playheadPosition: 5.0,
  height: 140,
)
```

---

### 3. Live Streaming / Real-time Audio Recording

```dart
WaveformData liveData = WaveformData(samples: [], durationSeconds: 0);

// As microphone buffer packets arrive:
void onAudioBufferReceived(List<double> newPeaks, double bufferDuration) {
  setState(() {
    liveData = liveData.append(newPeaks, addedDurationSeconds: bufferDuration);
  });
}
```

---

### 4. Headless PNG Image Export (Thumbnails / Notifications)

```dart
import 'dart:typed_data';
import 'package:waveform_pro/waveform_pro.dart';

Future<Uint8List> generateWaveformThumbnail(WaveformData data) async {
  return await WaveformExporter.toPngBytes(
    data: data,
    width: 600,
    height: 150,
    style: WaveformStyle.voiceMemo,
    playheadPosition: 20.0,
  );
}
```

---

## 🛠️ API Overview

| Class | Description |
| :--- | :--- |
| `WaveformTimeline` | Interactive Flutter widget with gesture support, time ruler, cue markers, and playhead. |
| `WaveformPainter` | Custom painter executing GPU-accelerated continuous, discrete bar, and spline rendering. |
| `WaveformRenderMode` | Enum (`continuous`, `bars`, `curvedSpline`) defining the visual geometry. |
| `WaveformStyle` | Styling configuration (bar width, gaps, radiuses, wave colors, played progress color). |
| `WaveformData` | Pyramid-cached sample container with `.generate()`, `.append()`, and multi-res getters. |
| `WaveformController` | Programmatic zoom, scroll, region selection, and marker management. |
| `WaveformExporter` | Headless rasterizer for exporting waveforms to PNG byte buffers. |

---

## 🧪 Testing

```bash
flutter test
```

---

## 🌐 Ecosystem & Related Packages

Explore complementary production-grade libraries built for high-performance Flutter & Dart development:

| Package | Description | Version |
| :--- | :--- | :--- |
| **[`ambient_backdrop_glow`](https://pub.dev/packages/ambient_backdrop_glow)** | Dynamic ambient background glow and fluid animated mesh gradients from image artwork with OKLab color blending for Flutter. | `^1.1.2` |
| **[`country_mobile_validator`](https://pub.dev/packages/country_mobile_validator)** | Validate mobile numbers per country using real length ranges (8-10, 10-11 digits), mobile-only detection, and a country_code_picker-friendly API. | `^0.2.1` |
| **[`cron_schedule`](https://pub.dev/packages/cron_schedule)** | Lightweight, pure-Dart cron parser, next-occurrence predictor, human-readable translator, and fluent schedule builder for Dart and Flutter. | `^1.1.1` |
| **[`currency_field_formatter`](https://pub.dev/packages/currency_field_formatter)** | Bulletproof Flutter currency TextInputFormatter with exact cursor tracking, backspace handling, Indian Lakhs/Crores, and ISO 4217 presets. | `^1.1.1` |
| **[`flutter_whisper`](https://pub.dev/packages/flutter_whisper)** | On-device speech-to-text transcription using whisper.cpp. Automatic model download, streaming segment results, Android support. | `^0.2.1` |
| **[`offline_outbox`](https://pub.dev/packages/offline_outbox)** | Resilient offline-first outbox and retry queue for Dart and Flutter with disk persistence, exponential backoff, priority scheduling, and deduplication. | `^1.1.1` |
| **[`quote_painter`](https://pub.dev/packages/quote_painter)** | Flutter package for rendering styled text on image/video canvas with gradient fill, stroke, shadow, decorative quotation marks, line badges, and themes. | `^0.2.4` |
| **[`scratch_reveal`](https://pub.dev/packages/scratch_reveal)** | High-performance GPU-accelerated scratch card and scratch-to-reveal canvas widget for Flutter with sub-millisecond bitmask progress tracking. | `^1.1.1` |
| **[`segmented_ring_painter`](https://pub.dev/packages/segmented_ring_painter)** | High-performance segmented circular progress and concentric activity ring widget for Flutter with gradient arcs, rounded caps, gap math, and tap hit-testing. | `^1.1.2` |

---

## 💖 Support the Project

If you find this package useful, consider supporting its active maintenance and future development:

<p align="left">
  <a href="https://buymeacoffee.com/govindtanko"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=govindtanko&button_colour=FFDD00&font_colour=000000&font_family=Poppins&outline_colour=000000&coffee_colour=FFDD00" alt="Buy Me A Coffee" height="40"/></a>
  &nbsp;
  <a href="https://github.com/sponsors/govindtank"><img src="https://img.shields.io/badge/GitHub%20Sponsors-Sponsor-EA4AAA?style=for-the-badge&logo=github&logoColor=white" alt="GitHub Sponsors" height="40"/></a>
  &nbsp;
  <a href="https://www.patreon.com/govindtank"><img src="https://img.shields.io/badge/Patreon-Support-F96854?style=for-the-badge&logo=patreon&logoColor=white" alt="Patreon" height="40"/></a>
</p>

---

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

*Maintained with ❤️ by [Govind Tank](https://github.com/govindtank).*
