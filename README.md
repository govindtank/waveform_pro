# waveform_pro

A production-quality Flutter waveform widget with GPU-accelerated rendering, zoom, region selection, cue markers, and audio peak extraction.

## Features

- ⚡ **GPU-accelerated rendering** — multi-resolution pyramid cache for efficient drawing at any zoom level
- 🔍 **Pinch-to-zoom & scroll** — zoom into micro-detail or see the full track
- 🎯 **Region selection** — highlight and select portions of the waveform
- 📌 **Cue markers** — annotate the timeline with labeled bookmarks
- 📏 **Time ruler** — adaptive tick marks that respond to zoom level
- 🎨 **Fully customizable styling** — colors, sizes, stroke widths
- 📱 **Touch-optimized** — gestures designed for mobile interaction
- 🔊 **Peak extraction** — utilities for WAV, PCM, and FFmpeg audio sources

## Installation

```yaml
dependencies:
  waveform_pro: ^1.0.0
```

Or use a Git dependency:

```yaml
dependencies:
  waveform_pro:
    git:
      url: https://github.com/govindtank/waveform_pro.git
```

## Quick Start

```dart
import 'package:waveform_pro/waveform_pro.dart';

// Generate synthetic waveform data for demo
final data = WaveformData.generate(
  sampleCount: 3000,
  durationSeconds: 30,
);

// Or extract from real audio:
// final bytes = await File('audio.wav').readAsBytes();
// final data = PeakExtractor.fromWavBytes(bytes);

// Display the waveform
WaveformTimeline(
  data: data,
  height: 140,
  style: const WaveformStyle(
    waveColor: Color(0xFF4CAF50),
  ),
  onTap: (timeSeconds) {
    print('Tapped at ${timeSeconds}s');
  },
);
```

## Full Example

```dart
import 'package:flutter/material.dart';
import 'package:waveform_pro/waveform_pro.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Waveform Pro')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: WaveformTimeline(
            data: WaveformData.generate(),
            controller: WaveformController(),
            enableZoom: true,
            enableMarkers: true,
          ),
        ),
      ),
    );
  }
}
```

## API Overview

### `WaveformData`

Holds peak samples with a multi-resolution pyramid cache.

```dart
WaveformData({
  required List<double> samples,  // normalized 0.0-1.0
  required double durationSeconds,
});

// Synthetic data for demos/tests:
WaveformData.generate({sampleCount: 2000, durationSeconds: 30});
```

### `WaveformTimeline`

The main widget.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | `WaveformData` | required | Waveform peak data |
| `controller` | `WaveformController?` | auto | Zoom/scroll/regions control |
| `style` | `WaveformStyle` | defaults | Colors and sizes |
| `height` | `double` | 120 | Widget height in pixels |
| `enableZoom` | `bool` | true | Pinch-to-zoom enabled |
| `enableRegionSelection` | `bool` | true | Region selection enabled |
| `enableMarkers` | `bool` | true | Long-press to add markers |
| `onTap` | `void Function(double)?` | — | Tap callback (time in seconds) |

### `WaveformController`

Manages zoom, scroll, region selections, and cue markers.

```dart
controller.zoomIn();                  // zoom in 1.5x
controller.zoomOut();                 // zoom out 1.5x
controller.resetZoom();              // fit all in viewport
controller.addRegion(WaveformRegion(startFraction: 0.2, endFraction: 0.5));
controller.addMarker(CueMarker(positionFraction: 0.75, label: 'Outro'));
controller.clearRegions();
controller.clearMarkers();
```

### `WaveformStyle`

Customize the visual appearance.

```dart
WaveformStyle(
  waveColor: Color(0xFF2196F3),
  backgroundColor: Color(0xFFF5F5F5),
  regionColor: Color(0x302196F3),
  centerLineColor: Color(0x1A000000),
  waveStrokeWidth: 1.0,
  topPadding: 2.0,
);
```

### `PeakExtractor`

Extract waveform data from audio files.

```dart
// From WAV bytes
final data = PeakExtractor.fromWavBytes(wavBytes);

// From raw PCM float samples
final data = PeakExtractor.fromPcmFloats(rawSamples, sampleRate: 44100);
```

## Audio Source Notes

For production use, extract peaks on a server or via FFmpeg:

- **Mobile:** Use `ffmpeg_kit_flutter` to extract raw PCM → `PeakExtractor.fromPcmFloats()`
- **Desktop:** Use `dart:io` Process + FFmpeg `-f f32le` output
- **Server:** Any audio processing library → export as JSON peak array

## Testing

```bash
flutter test
```

## License

Apache 2.0
