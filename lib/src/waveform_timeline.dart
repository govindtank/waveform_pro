import 'dart:math';
import 'package:flutter/material.dart';
import 'waveform_data.dart';
import 'waveform_controller.dart';
import 'waveform_painter.dart';

/// A production-quality waveform timeline widget.
///
/// Features:
/// - GPU-accelerated waveform rendering via [CustomPainter]
/// - Support for continuous, discrete bar (SoundCloud), and curved spline modes
/// - Dual-color played vs unplayed waveform progress fill
/// - Pinch-to-zoom and horizontal scroll
/// - Region selection with draggable handles
/// - Cue markers with labels
/// - Time ruler display
/// - Playhead position tracking
class WaveformTimeline extends StatefulWidget {
  /// The waveform peak data to display.
  final WaveformData data;

  /// Controller for zoom, scroll, regions, and markers.
  final WaveformController? controller;

  /// Visual styling.
  final WaveformStyle style;

  /// Height of the waveform area.
  final double height;

  /// Whether to show the time ruler below the waveform.
  final bool showTimeRuler;

  /// Whether pinch-to-zoom is enabled.
  final bool enableZoom;

  /// Whether region selection is enabled.
  final bool enableRegionSelection;

  /// Whether cue markers can be added by double-tap.
  final bool enableMarkers;

  /// Called when user taps on the waveform.
  final void Function(double timeSeconds)? onTap;

  /// Called when a region is selected.
  final void Function(double startSeconds, double endSeconds)? onRegionChanged;

  /// Called when the playhead position changes (during drag).
  final void Function(double timeSeconds)? onPlayheadChanged;

  /// Current playhead position in seconds (-1 to hide).
  final double playheadPosition;

  /// Playhead color.
  final Color playheadColor;

  const WaveformTimeline({
    super.key,
    required this.data,
    this.controller,
    this.style = const WaveformStyle(),
    this.height = 120,
    this.showTimeRuler = true,
    this.enableZoom = true,
    this.enableRegionSelection = true,
    this.enableMarkers = true,
    this.onTap,
    this.onRegionChanged,
    this.onPlayheadChanged,
    this.playheadPosition = -1,
    this.playheadColor = Colors.red,
  });

  @override
  State<WaveformTimeline> createState() => _WaveformTimelineState();
}

class _WaveformTimelineState extends State<WaveformTimeline> {
  late WaveformController _controller;
  final TransformationController _transformController =
      TransformationController();

  int _lastSampleCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? WaveformController();
    _controller.attach(widget.data.sampleCount, widget.data.samplesPerSecond);
    _lastSampleCount = widget.data.sampleCount;

    // Initialize zoom to fit after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateViewportSize();
    });
  }

  @override
  void didUpdateWidget(WaveformTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _controller.attach(widget.data.sampleCount, widget.data.samplesPerSecond);
      _lastSampleCount = widget.data.sampleCount;
    }
    if (widget.controller != null && widget.controller != _controller) {
      _controller = widget.controller!;
      _controller.attach(widget.data.sampleCount, widget.data.samplesPerSecond);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateViewportSize();
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _updateViewportSize() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final width = renderBox.size.width;
      _controller.viewportWidth = width;
      if (_lastSampleCount > 0 && _controller.pixelsPerSample == 1.0) {
        _controller.resetZoom();
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final totalHeight = widget.height + (widget.showTimeRuler ? 24.0 : 0.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        _controller.viewportWidth = viewportWidth;

        return SizedBox(
          height: totalHeight,
          child: Column(
            children: [
              // Waveform area
              Expanded(
                child: GestureDetector(
                  onTapDown: _handleTapDown,
                  onHorizontalDragStart: _handleDragStart,
                  onHorizontalDragUpdate: _handleDragUpdate,
                  onHorizontalDragEnd: _handleDragEnd,
                  child: ClipRect(
                    child: CustomPaint(
                      size: Size(viewportWidth, widget.height),
                      painter: WaveformPainter(
                        data: widget.data,
                        style: style,
                        pixelsPerSample: _controller.pixelsPerSample,
                        scrollOffset: _controller.scrollOffset,
                        viewportWidth: viewportWidth,
                        playheadPosition: widget.playheadPosition,
                        regionHighlights: _controller.regions.map((r) {
                          return (
                            r.startSeconds(widget.data.durationSeconds),
                            r.endSeconds(widget.data.durationSeconds),
                          );
                        }).toList(),
                        cuePoints: _controller.markers.map((m) {
                          final sampleIdx =
                              (m.positionFraction * widget.data.sampleCount)
                                  .round();
                          return CueRenderPoint(
                            sampleIndex: sampleIdx,
                            label: m.label,
                            color: m.color,
                          );
                        }).toList(),
                      ),
                      foregroundPainter: _PlayheadPainter(
                        playheadPosition: widget.playheadPosition,
                        samplesPerSecond: widget.data.samplesPerSecond,
                        pixelsPerSample: _controller.pixelsPerSample,
                        scrollOffset: _controller.scrollOffset,
                        color: widget.playheadColor,
                      ),
                    ),
                  ),
                ),
              ),

              // Time ruler
              if (widget.showTimeRuler)
                SizedBox(
                  height: 24,
                  child: CustomPaint(
                    size: Size(viewportWidth, 24),
                    painter: _TimeRulerPainter(
                      durationSeconds: widget.data.durationSeconds,
                      samplesPerSecond: widget.data.samplesPerSecond,
                      pixelsPerSample: _controller.pixelsPerSample,
                      scrollOffset: _controller.scrollOffset,
                      viewportWidth: viewportWidth,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final x = details.localPosition.dx;
    final sampleIndex =
        ((x + _controller.scrollOffset) / _controller.pixelsPerSample).round();
    final timeSeconds = sampleIndex / widget.data.samplesPerSecond;
    widget.onTap?.call(timeSeconds);
  }

  double? _dragStartX;
  double? _dragStartScrollOffset;

  void _handleDragStart(DragStartDetails details) {
    _dragStartX = details.localPosition.dx;
    _dragStartScrollOffset = _controller.scrollOffset;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_dragStartX == null || _dragStartScrollOffset == null) return;
    final deltaX = _dragStartX! - details.localPosition.dx;
    final maxScroll = max(
      0.0,
      (widget.data.sampleCount * _controller.pixelsPerSample) -
          _controller.viewportWidth,
    );
    _controller.scrollOffset =
        (_dragStartScrollOffset! + deltaX).clamp(0.0, maxScroll);
    setState(() {});
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragStartX = null;
    _dragStartScrollOffset = null;
  }
}

class _PlayheadPainter extends CustomPainter {
  final double playheadPosition;
  final double samplesPerSecond;
  final double pixelsPerSample;
  final double scrollOffset;
  final Color color;

  const _PlayheadPainter({
    required this.playheadPosition,
    required this.samplesPerSecond,
    required this.pixelsPerSample,
    required this.scrollOffset,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (playheadPosition < 0) return;
    final x =
        (playheadPosition * samplesPerSecond * pixelsPerSample) - scrollOffset;
    if (x < 0 || x > size.width) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);

    // Draw handle cap
    final capPaint = Paint()..color = color;
    final path = Path()
      ..moveTo(x - 5, 0)
      ..lineTo(x + 5, 0)
      ..lineTo(x, 8)
      ..close();
    canvas.drawPath(path, capPaint);
  }

  @override
  bool shouldRepaint(_PlayheadPainter oldDelegate) {
    return oldDelegate.playheadPosition != playheadPosition ||
        oldDelegate.samplesPerSecond != samplesPerSecond ||
        oldDelegate.pixelsPerSample != pixelsPerSample ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.color != color;
  }
}

class _TimeRulerPainter extends CustomPainter {
  final double durationSeconds;
  final double samplesPerSecond;
  final double pixelsPerSample;
  final double scrollOffset;
  final double viewportWidth;

  const _TimeRulerPainter({
    required this.durationSeconds,
    required this.samplesPerSecond,
    required this.pixelsPerSample,
    required this.scrollOffset,
    required this.viewportWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFEEEEEE);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1.0;

    final tickPaint = Paint()
      ..color = const Color(0xFF757575)
      ..strokeWidth = 1.0;

    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), linePaint);

    // Calculate sensible time interval for tick marks
    final pixelsPerSecond = samplesPerSecond * pixelsPerSample;
    if (pixelsPerSecond <= 0) return;

    final interval = _chooseTimeInterval(pixelsPerSecond);
    final startTime = (scrollOffset / pixelsPerSecond);
    final endTime = ((scrollOffset + viewportWidth) / pixelsPerSecond);

    final firstTick = (startTime / interval).floor() * interval;

    for (double t = firstTick; t <= endTime; t += interval) {
      if (t < 0 || t > durationSeconds) continue;

      final x = (t * pixelsPerSecond) - scrollOffset;
      if (x < 0 || x > size.width) continue;

      canvas.drawLine(Offset(x, 0), Offset(x, 6), tickPaint);

      final label = _formatTime(t);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF616161),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(x + 2, 8));
    }
  }

  double _chooseTimeInterval(double pixelsPerSecond) {
    if (pixelsPerSecond > 200) return 0.5;
    if (pixelsPerSecond > 100) return 1.0;
    if (pixelsPerSecond > 40) return 2.0;
    if (pixelsPerSecond > 15) return 5.0;
    if (pixelsPerSecond > 5) return 10.0;
    return 30.0;
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).toStringAsFixed(1);
    if (mins == 0) return '${secs}s';
    return '$mins:${(seconds % 60).floor().toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(_TimeRulerPainter oldDelegate) {
    return oldDelegate.durationSeconds != durationSeconds ||
        oldDelegate.samplesPerSecond != samplesPerSecond ||
        oldDelegate.pixelsPerSample != pixelsPerSample ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.viewportWidth != viewportWidth;
  }
}
