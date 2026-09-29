import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'waveform_data.dart';
import 'waveform_painter.dart';

/// Utilities for headless rendering and exporting waveforms to image bytes.
class WaveformExporter {
  const WaveformExporter._();

  /// Renders [WaveformData] directly to PNG image bytes without requiring a mounted widget.
  ///
  /// [width] and [height] specify the target image resolution in pixels.
  /// [style] specifies the waveform colors, mode (bars, continuous, curve), and line widths.
  static Future<Uint8List> toPngBytes({
    required WaveformData data,
    required double width,
    required double height,
    WaveformStyle style = WaveformStyle.defaults,
    double playheadPosition = -1,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final painter = WaveformPainter(
      data: data,
      style: style,
      pixelsPerSample: data.sampleCount > 0 ? width / data.sampleCount : 1.0,
      scrollOffset: 0.0,
      viewportWidth: width,
      playheadPosition: playheadPosition,
    );

    painter.paint(canvas, Size(width, height));

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}
