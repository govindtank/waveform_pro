import 'package:flutter/material.dart';
import 'waveform_data.dart';

/// High-performance [CustomPainter] for rendering audio waveforms.
///
/// Uses multi-resolution pyramid data for efficient rendering at any zoom level.
/// Renders as mirrored waveform (top and bottom from center) for the classic
/// audio waveform look.
class WaveformPainter extends CustomPainter {
  final WaveformData data;
  final WaveformStyle style;
  final double pixelsPerSample;
  final double scrollOffset;
  final double viewportWidth;
  final List<(double, double)>? regionHighlights;
  final List<CueRenderPoint>? cuePoints;

  WaveformPainter({
    required this.data,
    required this.style,
    required this.pixelsPerSample,
    required this.scrollOffset,
    required this.viewportWidth,
    this.regionHighlights,
    this.cuePoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // Calculate visible sample range
    final startSample =
        (scrollOffset / pixelsPerSample).floor().clamp(0, data.sampleCount - 1);
    final visibleSamples = (viewportWidth / pixelsPerSample).ceil() + 2;
    final endSample = (startSample + visibleSamples).clamp(0, data.sampleCount);

    if (startSample >= endSample) return;

    // Get appropriate resolution level
    final level = data.getLevel(visibleSamples);

    // Scale: map waveform sample index to level index
    final scale = data.sampleCount / level.length;

    // Calculate first level sample
    final levelStart = (startSample / scale).floor().clamp(0, level.length - 1);
    final levelEnd = (endSample / scale).ceil().clamp(0, level.length);

    if (levelStart >= levelEnd) return;

    // ---- Draw background ----
    final bgPaint = Paint()..color = style.backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // ---- Draw region highlights ----
    if (regionHighlights != null) {
      final regionPaint = Paint()..color = style.regionColor;
      for (final (startSec, endSec) in regionHighlights!) {
        final startX =
            (startSec * data.samplesPerSecond * pixelsPerSample) - scrollOffset;
        final endX =
            (endSec * data.samplesPerSecond * pixelsPerSample) - scrollOffset;
        if (endX < 0 || startX > size.width) continue;
        canvas.drawRect(
          Rect.fromLTRB(
            startX.clamp(0, size.width),
            0,
            endX.clamp(0, size.width),
            size.height,
          ),
          regionPaint,
        );
      }
    }

    // ---- Draw waveform ----
    final paint = Paint()
      ..color = style.waveColor
      ..strokeWidth = style.waveStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final maxAmplitude = centerY - style.topPadding;

    final path = Path();
    bool pathStarted = false;

    for (int i = levelStart; i < levelEnd; i++) {
      final sampleIndex = (i * scale).round();
      final x = (sampleIndex * pixelsPerSample) - scrollOffset;

      if (x < -pixelsPerSample || x > size.width + pixelsPerSample) continue;

      final amplitude = level[i] * maxAmplitude;

      if (!pathStarted) {
        path.moveTo(x, centerY - amplitude);
        pathStarted = true;
      }

      // Top half
      path.lineTo(x, centerY - amplitude);
    }

    // Mirror back for bottom half
    for (int i = levelEnd - 1; i >= levelStart; i--) {
      final sampleIndex = (i * scale).round();
      final x = (sampleIndex * pixelsPerSample) - scrollOffset;

      if (x < -pixelsPerSample || x > size.width + pixelsPerSample) continue;

      final amplitude = level[i] * maxAmplitude;
      path.lineTo(x, centerY + amplitude);
    }

    path.close();
    canvas.drawPath(path, paint);

    // ---- Draw center line ----
    final centerPaint = Paint()
      ..color = style.centerLineColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerPaint,
    );

    // ---- Draw cue points ----
    if (cuePoints != null) {
      for (final cue in cuePoints!) {
        final x = (cue.sampleIndex * pixelsPerSample) - scrollOffset;
        if (x < 0 || x > size.width) continue;

        // Cue line
        final cuePaint = Paint()
          ..color = cue.color
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), cuePaint);

        // Cue label
        if (cue.label.isNotEmpty) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: cue.label,
              style: TextStyle(
                color: cue.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(
            canvas,
            Offset(x + 4, 4),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.pixelsPerSample != pixelsPerSample ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.style != style;
  }
}

/// Styling configuration for the waveform.
class WaveformStyle {
  final Color waveColor;
  final Color backgroundColor;
  final Color regionColor;
  final Color centerLineColor;
  final double waveStrokeWidth;
  final double topPadding;

  const WaveformStyle({
    this.waveColor = const Color(0xFF2196F3),
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.regionColor = const Color(0x302196F3),
    this.centerLineColor = const Color(0x1A000000),
    this.waveStrokeWidth = 1.0,
    this.topPadding = 2.0,
  });

  static const WaveformStyle defaults = WaveformStyle();

  WaveformStyle copyWith({
    Color? waveColor,
    Color? backgroundColor,
    Color? regionColor,
    Color? centerLineColor,
    double? waveStrokeWidth,
    double? topPadding,
  }) {
    return WaveformStyle(
      waveColor: waveColor ?? this.waveColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      regionColor: regionColor ?? this.regionColor,
      centerLineColor: centerLineColor ?? this.centerLineColor,
      waveStrokeWidth: waveStrokeWidth ?? this.waveStrokeWidth,
      topPadding: topPadding ?? this.topPadding,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaveformStyle &&
          waveColor == other.waveColor &&
          backgroundColor == other.backgroundColor &&
          regionColor == other.regionColor &&
          centerLineColor == other.centerLineColor &&
          waveStrokeWidth == other.waveStrokeWidth &&
          topPadding == other.topPadding);

  @override
  int get hashCode => Object.hash(
        waveColor,
        backgroundColor,
        regionColor,
        centerLineColor,
        waveStrokeWidth,
        topPadding,
      );
}

/// Internal data class for cue point rendering.
class CueRenderPoint {
  final int sampleIndex;
  final String label;
  final Color color;

  const CueRenderPoint({
    required this.sampleIndex,
    this.label = '',
    this.color = Colors.red,
  });
}
