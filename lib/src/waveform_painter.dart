import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'waveform_data.dart';

/// Rendering styles for the audio waveform.
enum WaveformRenderMode {
  /// Classic continuous mirrored envelope path.
  continuous,

  /// Discrete vertical rounded bars (SoundCloud / Voice memo style).
  bars,

  /// Smooth bezier curved spline envelope.
  curvedSpline,
}

/// High-performance [CustomPainter] for rendering audio waveforms.
///
/// Uses multi-resolution pyramid data for efficient rendering at any zoom level.
/// Supports continuous paths, discrete bars, smooth curves, and played progress highlights.
class WaveformPainter extends CustomPainter {
  final WaveformData data;
  final WaveformStyle style;
  final double pixelsPerSample;
  final double scrollOffset;
  final double viewportWidth;
  final List<(double, double)>? regionHighlights;
  final List<CueRenderPoint>? cuePoints;
  final double playheadPosition;

  WaveformPainter({
    required this.data,
    required this.style,
    required this.pixelsPerSample,
    required this.scrollOffset,
    required this.viewportWidth,
    this.regionHighlights,
    this.cuePoints,
    this.playheadPosition = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    if (data.sampleCount == 0) {
      final bgPaint = Paint()..color = style.backgroundColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
      return;
    }

    // Calculate visible sample range
    final startSample =
        (scrollOffset / pixelsPerSample).floor().clamp(0, data.sampleCount - 1);
    final visibleSamples = (viewportWidth / pixelsPerSample).ceil() + 2;
    final endSample = (startSample + visibleSamples).clamp(0, data.sampleCount);

    if (startSample >= endSample) return;

    // Get appropriate resolution level
    final level = data.getLevel(visibleSamples);
    if (level.isEmpty) return;

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

    final playheadX = playheadPosition >= 0
        ? (playheadPosition * data.samplesPerSecond * pixelsPerSample) -
            scrollOffset
        : -1.0;

    final maxAmplitude = centerY - style.topPadding;

    // ---- Draw waveform according to render mode ----
    switch (style.renderMode) {
      case WaveformRenderMode.bars:
        _paintBars(
          canvas,
          size,
          level,
          levelStart,
          levelEnd,
          scale,
          centerY,
          maxAmplitude,
          playheadX,
        );
        break;
      case WaveformRenderMode.curvedSpline:
        _paintCurvedSpline(
          canvas,
          size,
          level,
          levelStart,
          levelEnd,
          scale,
          centerY,
          maxAmplitude,
          playheadX,
        );
        break;
      case WaveformRenderMode.continuous:
        _paintContinuous(
          canvas,
          size,
          level,
          levelStart,
          levelEnd,
          scale,
          centerY,
          maxAmplitude,
          playheadX,
        );
        break;
    }

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

  void _paintBars(
    Canvas canvas,
    Size size,
    List<double> level,
    int levelStart,
    int levelEnd,
    double scale,
    double centerY,
    double maxAmplitude,
    double playheadX,
  ) {
    final barWidth = style.barWidth;
    final barSpacing = style.barSpacing;
    final totalBarStep = barWidth + barSpacing;

    for (int i = levelStart; i < levelEnd; i++) {
      final sampleIndex = (i * scale).round();
      final x = (sampleIndex * pixelsPerSample) - scrollOffset;

      if (x < -totalBarStep || x > size.width + totalBarStep) continue;

      final amplitude =
          math.max(style.minBarHeight, level[i] * maxAmplitude * 2);
      final isPlayed = playheadX >= 0 && x <= playheadX;

      final paint = Paint()
        ..color = isPlayed ? style.playedWaveColor : style.waveColor
        ..style = PaintingStyle.fill;

      final rect = Rect.fromCenter(
        center: Offset(x, centerY),
        width: barWidth,
        height: amplitude,
      );

      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(style.barRadius),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  void _paintContinuous(
    Canvas canvas,
    Size size,
    List<double> level,
    int levelStart,
    int levelEnd,
    double scale,
    double centerY,
    double maxAmplitude,
    double playheadX,
  ) {
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

    _renderWaveformPath(canvas, size, path, playheadX);
  }

  void _paintCurvedSpline(
    Canvas canvas,
    Size size,
    List<double> level,
    int levelStart,
    int levelEnd,
    double scale,
    double centerY,
    double maxAmplitude,
    double playheadX,
  ) {
    final topPoints = <Offset>[];
    final bottomPoints = <Offset>[];

    for (int i = levelStart; i < levelEnd; i++) {
      final sampleIndex = (i * scale).round();
      final x = (sampleIndex * pixelsPerSample) - scrollOffset;
      if (x < -pixelsPerSample * 2 || x > size.width + pixelsPerSample * 2) {
        continue;
      }

      final amplitude = level[i] * maxAmplitude;
      topPoints.add(Offset(x, centerY - amplitude));
      bottomPoints.add(Offset(x, centerY + amplitude));
    }

    if (topPoints.isEmpty) return;

    final path = Path()..moveTo(topPoints.first.dx, topPoints.first.dy);

    for (int i = 0; i < topPoints.length - 1; i++) {
      final p0 = topPoints[i];
      final p1 = topPoints[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    for (int i = bottomPoints.length - 1; i >= 0; i--) {
      final p = bottomPoints[i];
      if (i == bottomPoints.length - 1) {
        path.lineTo(p.dx, p.dy);
      } else {
        final pNext = bottomPoints[i + 1];
        final midX = (p.dx + pNext.dx) / 2;
        path.cubicTo(midX, pNext.dy, midX, p.dy, p.dx, p.dy);
      }
    }

    path.close();

    _renderWaveformPath(canvas, size, path, playheadX);
  }

  void _renderWaveformPath(
    Canvas canvas,
    Size size,
    Path path,
    double playheadX,
  ) {
    final paint = Paint()
      ..color = style.waveColor
      ..strokeWidth = style.waveStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = style.fillWaveform ? PaintingStyle.fill : PaintingStyle.stroke;

    if (playheadX > 0 && playheadX < size.width) {
      // Draw played part
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, playheadX, size.height));
      final playedPaint = Paint()
        ..color = style.playedWaveColor
        ..strokeWidth = style.waveStrokeWidth
        ..strokeCap = StrokeCap.round
        ..style =
            style.fillWaveform ? PaintingStyle.fill : PaintingStyle.stroke;
      canvas.drawPath(path, playedPaint);
      canvas.restore();

      // Draw unplayed remainder
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(playheadX, 0, size.width - playheadX, size.height),
      );
      canvas.drawPath(path, paint);
      canvas.restore();
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.pixelsPerSample != pixelsPerSample ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.viewportWidth != viewportWidth ||
        oldDelegate.playheadPosition != playheadPosition ||
        oldDelegate.style != style;
  }
}

/// Styling configuration for the waveform.
class WaveformStyle {
  final Color waveColor;
  final Color playedWaveColor;
  final Color backgroundColor;
  final Color regionColor;
  final Color centerLineColor;
  final double waveStrokeWidth;
  final double topPadding;
  final WaveformRenderMode renderMode;
  final double barWidth;
  final double barSpacing;
  final double barRadius;
  final double minBarHeight;
  final bool fillWaveform;

  const WaveformStyle({
    this.waveColor = const Color(0xFF2196F3),
    this.playedWaveColor = const Color(0xFF1565C0),
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.regionColor = const Color(0x302196F3),
    this.centerLineColor = const Color(0x1A000000),
    this.waveStrokeWidth = 1.0,
    this.topPadding = 2.0,
    this.renderMode = WaveformRenderMode.continuous,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
    this.barRadius = 2.0,
    this.minBarHeight = 2.0,
    this.fillWaveform = false,
  });

  static const WaveformStyle defaults = WaveformStyle();

  /// Preset for modern discrete voice memo / SoundCloud style bars.
  static const WaveformStyle voiceMemo = WaveformStyle(
    renderMode: WaveformRenderMode.bars,
    waveColor: Color(0xFF90CAF9),
    playedWaveColor: Color(0xFF1976D2),
    backgroundColor: Colors.transparent,
    barWidth: 3.5,
    barSpacing: 2.0,
    barRadius: 2.5,
    minBarHeight: 3.0,
  );

  /// Preset for sleek neon curved aesthetic.
  static const WaveformStyle neonGlow = WaveformStyle(
    renderMode: WaveformRenderMode.curvedSpline,
    waveColor: Color(0xFF00E5FF),
    playedWaveColor: Color(0xFFFF007F),
    backgroundColor: Color(0xFF0F172A),
    centerLineColor: Color(0x3300E5FF),
    waveStrokeWidth: 1.8,
  );

  WaveformStyle copyWith({
    Color? waveColor,
    Color? playedWaveColor,
    Color? backgroundColor,
    Color? regionColor,
    Color? centerLineColor,
    double? waveStrokeWidth,
    double? topPadding,
    WaveformRenderMode? renderMode,
    double? barWidth,
    double? barSpacing,
    double? barRadius,
    double? minBarHeight,
    bool? fillWaveform,
  }) {
    return WaveformStyle(
      waveColor: waveColor ?? this.waveColor,
      playedWaveColor: playedWaveColor ?? this.playedWaveColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      regionColor: regionColor ?? this.regionColor,
      centerLineColor: centerLineColor ?? this.centerLineColor,
      waveStrokeWidth: waveStrokeWidth ?? this.waveStrokeWidth,
      topPadding: topPadding ?? this.topPadding,
      renderMode: renderMode ?? this.renderMode,
      barWidth: barWidth ?? this.barWidth,
      barSpacing: barSpacing ?? this.barSpacing,
      barRadius: barRadius ?? this.barRadius,
      minBarHeight: minBarHeight ?? this.minBarHeight,
      fillWaveform: fillWaveform ?? this.fillWaveform,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaveformStyle &&
          waveColor == other.waveColor &&
          playedWaveColor == other.playedWaveColor &&
          backgroundColor == other.backgroundColor &&
          regionColor == other.regionColor &&
          centerLineColor == other.centerLineColor &&
          waveStrokeWidth == other.waveStrokeWidth &&
          topPadding == other.topPadding &&
          renderMode == other.renderMode &&
          barWidth == other.barWidth &&
          barSpacing == other.barSpacing &&
          barRadius == other.barRadius &&
          minBarHeight == other.minBarHeight &&
          fillWaveform == other.fillWaveform);

  @override
  int get hashCode => Object.hash(
        waveColor,
        playedWaveColor,
        backgroundColor,
        regionColor,
        centerLineColor,
        waveStrokeWidth,
        topPadding,
        renderMode,
        barWidth,
        barSpacing,
        barRadius,
        minBarHeight,
        fillWaveform,
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
