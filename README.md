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
  waveform_pro: ^1.1.0
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
| **[`country_mobile_validator`](https://pub.dev/packages/country_mobile_validator)** | Zero-dependency per-country mobile validation (249 ISO regions). | `^0.2.0` |
| **[`currency_field_formatter`](https://pub.dev/packages/currency_field_formatter)** | Exact cursor-tracking currency and financial input formatter. | `^1.1.0` |
| **[`ambient_backdrop_glow`](https://pub.dev/packages/ambient_backdrop_glow)** | Dynamic ambient background glow & fluid OKLab mesh gradients. | `^1.1.0` |
| **[`segmented_ring_painter`](https://pub.dev/packages/segmented_ring_painter)** | High-performance segmented progress & concentric activity rings. | `^1.1.0` |
| **[`scratch_reveal`](https://pub.dev/packages/scratch_reveal)** | GPU-accelerated scratch cards with sub-ms bitmask area tracking. | `^1.1.0` |
| **[`offline_outbox`](https://pub.dev/packages/offline_outbox)** | Offline-first resilient transactional outbox and retry queue. | `^1.1.0` |
| **[`cron_schedule`](https://pub.dev/packages/cron_schedule)** | Pure-Dart cron expression parser, predictor & fluent builder. | `^1.1.0` |
| **[`flutter_whisper`](https://pub.dev/packages/flutter_whisper)** | On-device speech-to-text transcription powered by whisper.cpp. | `^0.2.0` |
| **[`quote_painter`](https://pub.dev/packages/quote_painter)** | Canvas text styling with gradients, shadows, line badges & themes. | `^0.2.2` |

---

## 📄 License

This package is licensed under the [MIT License](LICENSE).
