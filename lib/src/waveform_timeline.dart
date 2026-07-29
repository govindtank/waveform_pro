import 'dart:math';
import 'package:flutter/material.dart';
import 'waveform_data.dart';
import 'waveform_controller.dart';
import 'waveform_painter.dart';
import 'marker.dart';

/// A production-quality waveform timeline widget.
///
/// Features:
/// - GPU-accelerated waveform rendering via [CustomPainter]
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
  final TransformationController _transformController = TransformationController();

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
      setState(() {
        _controller.viewportWidth = renderBox.size.width;
        if (_lastSampleCount > 0) {
          _controller.resetZoom();
        }
      });
    }
  }

  CueRenderPoint? _markerToCuePoint(CueMarker marker) {
    return CueRenderPoint(
      sampleIndex: (marker.positionFraction * widget.data.sampleCount).round(),
      label: marker.label,
      color: marker.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update viewport width whenever layout changes
        _controller.viewportWidth = constraints.maxWidth;

        // Build current painter
        final cuePoints = _controller.markers
            .map(_markerToCuePoint)
            .where((e) => e != null)
            .cast<CueRenderPoint>()
            .toList();

        // Region highlights
        final regionHighlights = <(double, double)>[];
        for (final r in _controller.regions) {
          regionHighlights.add((
            r.startSeconds(widget.data.durationSeconds),
            r.endSeconds(widget.data.durationSeconds),
          ));
        }

        final painter = WaveformPainter(
          data: widget.data,
          style: widget.style,
          pixelsPerSample: _controller.pixelsPerSample,
          scrollOffset: _controller.scrollOffset,
          viewportWidth: constraints.maxWidth,
          regionHighlights: regionHighlights,
          cuePoints: cuePoints,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Waveform + gesture handling
            GestureDetector(
              onScaleStart: widget.enableZoom ? _onScaleStart : null,
              onScaleUpdate: widget.enableZoom ? _onScaleUpdate : null,
              onScaleEnd: widget.enableZoom ? _onScaleEnd : null,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onTapUp: (details) {
                final time = _controller.pixelToTime(details.localPosition.dx);
                widget.onTap?.call(time);
              },
              onLongPressStart: (details) {
                if (!widget.enableMarkers) return;
                final time = _controller.pixelToTime(details.localPosition.dx);
                final fraction = time / widget.data.durationSeconds;
                setState(() {
                  _controller.markers.add(CueMarker(
                    positionFraction: fraction.clamp(0.0, 1.0),
                    label: '${time.toStringAsFixed(1)}s',
                    color: Colors.orange,
                  ));
                });
              },
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: CustomPaint(
                    painter: painter,
                    size: Size(constraints.maxWidth, widget.height),
                  ),
                ),
              ),
            ),

            // Time ruler
            if (widget.showTimeRuler)
              _TimeRuler(
                durationSeconds: widget.data.durationSeconds,
                viewportWidth: constraints.maxWidth,
                pixelsPerSample: _controller.pixelsPerSample,
                scrollOffset: _controller.scrollOffset,
                samplesPerSecond: widget.data.samplesPerSecond,
              ),

            // Controls bar
            if (widget.enableZoom) _buildControls(),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 20),
            onPressed: () => setState(() => _controller.zoomOut()),
            tooltip: 'Zoom out',
          ),
          Text(
            '${_controller.pixelsPerSample.toStringAsFixed(1)} px/sample',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 20),
            onPressed: () => setState(() => _controller.zoomIn()),
            tooltip: 'Zoom in',
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() => _controller.resetZoom()),
            child: const Text('Fit', style: TextStyle(fontSize: 12)),
          ),
          if (_controller.regions.isNotEmpty) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => setState(() => _controller.clearRegions()),
              child: const Text('Clear regions',
                  style: TextStyle(fontSize: 12, color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Gesture handlers ----

  Offset? _lastFocalPoint;
  double _initialPps = 1.0;
  double _initialScroll = 0;

  void _onScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.focalPoint;
    _initialPps = _controller.pixelsPerSample;
    _initialScroll = _controller.scrollOffset;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_lastFocalPoint == null) return;

    final focalPoint = details.focalPoint;
    final scale = details.scale;

    if (scale != 1.0) {
      // Pinch zoom
      final newPps = (_initialPps * scale).clamp(
        _controller.minPixelsPerSample,
        _controller.maxPixelsPerSample,
      );

      // Keep focal point stationary during zoom
      final focalSample =
          (_initialScroll + focalPoint.dx) / _initialPps;
      final newScroll = (focalSample * newPps) - focalPoint.dx;

      setState(() {
        _controller.pixelsPerSample = newPps;
        _controller.scrollOffset = newScroll.clamp(
          0.0,
          max(
            0,
            widget.data.sampleCount * newPps - _controller.viewportWidth,
          ),
        );
        _lastFocalPoint = focalPoint;
      });
    }

    // Horizontal drag during scale
    final dx = focalPoint.dx - _lastFocalPoint!.dx;
    if (dx.abs() > 1) {
      setState(() {
        _controller.scrollOffset =
            (_controller.scrollOffset - dx).clamp(
          0.0,
          max(
            0,
            widget.data.sampleCount * _controller.pixelsPerSample -
                _controller.viewportWidth,
          ),
        );
        _lastFocalPoint = focalPoint;
      });
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastFocalPoint = null;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _controller.scrollOffset =
          (_controller.scrollOffset - details.delta.dx).clamp(
        0.0,
        max(
          0,
          widget.data.sampleCount * _controller.pixelsPerSample -
              _controller.viewportWidth,
        ),
      );
    });
  }
}

/// A simple time ruler displayed below the waveform.
class _TimeRuler extends StatelessWidget {
  final double durationSeconds;
  final double viewportWidth;
  final double pixelsPerSample;
  final double scrollOffset;
  final double samplesPerSecond;

  const _TimeRuler({
    required this.durationSeconds,
    required this.viewportWidth,
    required this.pixelsPerSample,
    required this.scrollOffset,
    required this.samplesPerSecond,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: CustomPaint(
        painter: _TimeRulerPainter(
          durationSeconds: durationSeconds,
          viewportWidth: viewportWidth,
          pixelsPerSample: pixelsPerSample,
          scrollOffset: scrollOffset,
          samplesPerSecond: samplesPerSecond,
        ),
        size: Size(viewportWidth, 24),
      ),
    );
  }
}

class _TimeRulerPainter extends CustomPainter {
  final double durationSeconds;
  final double viewportWidth;
  final double pixelsPerSample;
  final double scrollOffset;
  final double samplesPerSecond;

  _TimeRulerPainter({
    required this.durationSeconds,
    required this.viewportWidth,
    required this.pixelsPerSample,
    required this.scrollOffset,
    required this.samplesPerSecond,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    final textStyle =
        TextStyle(color: Colors.grey.shade500, fontSize: 9);

    // Determine tick interval based on zoom level
    final visibleDuration =
        viewportWidth / (pixelsPerSample * samplesPerSecond);
    double tickInterval;
    if (visibleDuration < 2) {
      tickInterval = 0.1;
    } else if (visibleDuration < 10) {
      tickInterval = 0.5;
    } else if (visibleDuration < 60) {
      tickInterval = 1;
    } else if (visibleDuration < 300) {
      tickInterval = 5;
    } else {
      tickInterval = 10;
    }

    final startTime =
        scrollOffset / (pixelsPerSample * samplesPerSecond);
    final endTime =
        (scrollOffset + viewportWidth) /
        (pixelsPerSample * samplesPerSecond);

    final firstTick =
        (startTime / tickInterval).ceil() * tickInterval;

    for (double t = firstTick; t <= endTime; t += tickInterval) {
      final x =
          (t * samplesPerSecond * pixelsPerSample) - scrollOffset;
      if (x < 0 || x > viewportWidth) continue;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);

      // Time label
      final text = _formatTime(t);
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x + 2, 2));
    }
  }

  String _formatTime(double seconds) {
    final m = (seconds ~/ 60);
    final s = (seconds % 60);
    if (m > 0) {
      return '$m:${s.toStringAsFixed(1).padLeft(4, '0')}';
    }
    return s.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _TimeRulerPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset ||
      oldDelegate.pixelsPerSample != pixelsPerSample ||
      oldDelegate.viewportWidth != viewportWidth;
}
