# waveform_pro

[![Pub Version](https://img.shields.io/pub/v/waveform_pro.svg?style=flat-square&color=blue)](https://pub.dev/packages/waveform_pro)
[![Pub Points](https://img.shields.io/pub/points/waveform_pro?style=flat-square&color=2E8B57&label=pub%20points)](https://pub.dev/packages/waveform_pro/score)
[![Pub Likes](https://img.shields.io/pub/likes/waveform_pro?style=flat-square)](https://pub.dev/packages/waveform_pro)
[![CI](https://github.com/govindtank/waveform_pro/actions/workflows/ci.yml/badge.svg)](https://github.com/govindtank/waveform_pro/actions)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-blue?style=flat-square)](https://pub.dev/packages/waveform_pro)

A production-quality Flutter waveform audio visualization widget with GPU-accelerated rendering, multi-resolution pyramid caching, smooth pinch-to-zoom, region selection, cue markers, time ruler, and audio peak extraction.

Now available on **[pub.dev/packages/waveform_pro](https://pub.dev/packages/waveform_pro)**.

---

<p align="center">
  <img src="https://raw.githubusercontent.com/govindtank/waveform_pro/main/screenshot.svg" width="750" alt="waveform_pro demo screenshot"/>
</p>

---

## ⚡ Features

- 🚀 **GPU-Accelerated Rendering** — Multi-resolution pyramid cache dynamically selects the optimal LOD (Level of Detail) sample density for 60fps / 120fps butter-smooth rendering at any zoom level.
- 🔍 **Pinch-to-Zoom & Pan** — Fluid zooming into sub-millisecond waveform details or zooming out to view the entire audio track.
- 🎯 **Region Selection** — Intuitive drag-to-select regions for audio trimming, looping, snippet export, and range playback.
- 📌 **Cue Markers** — Annotate waveforms with custom-styled bookmarks, labels, and icons.
- 📏 **Adaptive Time Ruler** — Dynamic timecode tick ruler that automatically adapts interval resolution (hours, minutes, seconds, milliseconds) based on zoom.
- 🎨 **Deeply Customizable Styling** — Custom colors, center line, stroke widths, padding, gradients, and selection overlay themes.
- 🔊 **Built-in Peak Extractor** — Direct peak calculation helpers for 16-bit / 8-bit WAV bytes, PCM float streams, and FFmpeg pipes.
- 📱 **Cross-Platform & Touch-Optimized** — Supports Android, iOS, Web, macOS, Windows, and Linux.

---

## 📦 Installation

Add `waveform_pro` to your Flutter app:

```bash
flutter pub add waveform_pro
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  waveform_pro: ^1.0.2
```

Import the package:

```dart
import 'package:waveform_pro/waveform_pro.dart';
```

---

## 🚀 Quick Start

### 1. Simple Interactive Waveform

Render a basic interactive waveform with synthetic sample data:

```dart
import 'package:flutter/material.dart';
import 'package:waveform_pro/waveform_pro.dart';

class SimpleWaveformExample extends StatelessWidget {
  const SimpleWaveformExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate synthetic peak samples for a 30s track
    final waveformData = WaveformData.generate(
      sampleCount: 3000,
      durationSeconds: 30,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Waveform Pro')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: WaveformTimeline(
            data: waveformData,
            height: 140,
            style: const WaveformStyle(
              waveColor: Color(0xFF2196F3),
              backgroundColor: Color(0xFFF0F4F8),
            ),
            showTimeRuler: true,
            enableZoom: true,
            onTap: (timeInSeconds) {
              print('User tapped at: ${timeInSeconds.toStringAsFixed(2)}s');
            },
          ),
        ),
      ),
    );
  }
}
```

---

## 🎛️ Controller Usage

Use `WaveformController` to programmatically control zoom levels, scrolling, highlighted regions, and cue markers.

```dart
final controller = WaveformController(
  initialPixelsPerSample: 2.0,
  maxPixelsPerSample: 100.0,
  minPixelsPerSample: 0.1,
);

WaveformTimeline(
  data: data,
  controller: controller,
  height: 140,
);

// Programmatic zoom & navigation
controller.zoomIn();             // 1.5x zoom in
controller.zoomOut(2.0);         // 2x zoom out
controller.resetZoom();          // Fit entire track within viewport
controller.scrollToTime(14.5);   // Scroll directly to 14.5-second mark

// Subscribe to state changes
controller.onZoomChanged = (pps) => print('Current zoom: $pps px/sample');
controller.onScrollChanged = (offset) => print('Current scroll offset: $offset px');

// Read visible range
final (startTime, endTime) = controller.visibleTimeRange;
print('Visible window: ${startTime}s – ${endTime}s');
```

---

## 📍 Regions & Cue Markers

Easily add, style, and manage regions (for audio loop/trim) and labeled markers (for beats/cues):

```dart
final controller = WaveformController();

// 1. Highlight a region (e.g. Chorus between 20% and 50% of track)
controller.addRegion(WaveformRegion(
  startFraction: 0.2,
  endFraction: 0.5,
  color: const Color(0x404CAF50),
  label: 'Chorus Loop',
));

// 2. Place cue marker
controller.addMarker(CueMarker(
  positionFraction: 0.75,
  label: 'Drop / Solo',
  color: Colors.deepOrange,
  icon: Icons.flag,
));

// 3. Connect to widget with region selection enabled
WaveformTimeline(
  data: data,
  controller: controller,
  enableRegionSelection: true,
  enableMarkers: true,
  onRegionChanged: (startSec, endSec) {
    print('Selected region: ${startSec.toStringAsFixed(2)}s to ${endSec.toStringAsFixed(2)}s');
  },
);
```

---

## 🔊 Peak Extraction from Real Audio

Extract normalized waveform peaks from audio bytes or raw PCM floats:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:waveform_pro/waveform_pro.dart';

// Option A: Extract from WAV file bytes (16-bit / 8-bit PCM)
final Uint8List wavBytes = await File('recording.wav').readAsBytes();
final WaveformData wavData = PeakExtractor.fromWavBytes(
  wavBytes,
  targetSamples: 4000,
);

// Option B: Extract from raw PCM float samples (-1.0 to 1.0)
final List<double> pcmFloats = [/* ... audio samples ... */];
final WaveformData pcmData = PeakExtractor.fromPcmFloats(
  pcmFloats,
  sampleRate: 44100,
  targetSamples: 2000,
);
```

---

## 📚 API Reference

### `WaveformData`
Stores raw peak samples and builds an LOD pyramid cache:

| Constructor / Method | Description |
|---|---|
| `WaveformData({required List<double> samples, required double durationSeconds})` | Constructs data from normalized peaks (0.0 – 1.0). |
| `WaveformData.generate({int sampleCount, double durationSeconds, double noiseLevel})` | Creates synthetic data for demos and unit tests. |
| `getLevel(int visibleSamples)` | Fetches the pre-calculated pyramid downsample level for optimal rendering performance. |

---

### `WaveformTimeline`
Main interactive widget for displaying and interacting with the waveform:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `data` | `WaveformData` | **required** | Peak sample data to render. |
| `controller` | `WaveformController?` | `null` | External controller for zoom, scroll, regions, and markers. |
| `style` | `WaveformStyle` | `WaveformStyle()` | Color and dimension styling. |
| `height` | `double` | `120.0` | Widget height in logical pixels. |
| `showTimeRuler` | `bool` | `true` | Toggles the time ruler beneath the waveform. |
| `enableZoom` | `bool` | `true` | Allows user pinch-to-zoom gestures. |
| `enableRegionSelection` | `bool` | `true` | Allows click-and-drag region selection. |
| `enableMarkers` | `bool` | `true` | Allows long-press to add cue markers. |
| `playheadPosition` | `double` | `-1.0` | Active playhead time position in seconds (`-1` hides playhead). |
| `playheadColor` | `Color` | `Colors.red` | Playhead line and cursor color. |
| `onTap` | `void Function(double)?` | `null` | Tap callback with position in seconds. |
| `onRegionChanged` | `void Function(double, double)?` | `null` | Triggered when region start/end bounds are dragged. |
| `onPlayheadChanged` | `void Function(double)?` | `null` | Triggered when playhead is scrubbed. |

---

### `WaveformStyle`
Styling configuration:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `waveColor` | `Color` | `Color(0xFF2196F3)` | Waveform bar / stroke color. |
| `backgroundColor` | `Color` | `Color(0xFFF5F5F5)` | Background container color. |
| `regionColor` | `Color` | `Color(0x302196F3)` | Region highlight selection fill. |
| `centerLineColor` | `Color` | `Color(0x1A000000)` | Horizontal center axis line color. |
| `waveStrokeWidth` | `double` | `1.0` | Thickness of individual waveform vertical sample bars. |
| `topPadding` | `double` | `2.0` | Top and bottom padding inside canvas. |

---

## 🧪 Testing

```bash
flutter test
flutter analyze
```

---

## 📄 License

Apache-2.0 License. See [LICENSE](LICENSE) for details.
