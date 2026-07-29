import 'package:flutter/material.dart';

/// A selected region on the waveform timeline.
///
/// Defined by start and end fractions (0.0–1.0 of total duration).
class WaveformRegion {
  /// Start position as fraction of total duration (0.0–1.0).
  double startFraction;

  /// End position as fraction of total duration (0.0–1.0).
  double endFraction;

  /// Highlight color for this region.
  final Color color;

  /// Optional label for the region.
  final String label;

  WaveformRegion({
    required this.startFraction,
    required this.endFraction,
    this.color = const Color(0x302196F3),
    this.label = '',
  });

  /// Start position in seconds given total duration.
  double startSeconds(double totalDuration) => startFraction * totalDuration;

  /// End position in seconds given total duration.
  double endSeconds(double totalDuration) => endFraction * totalDuration;

  /// Duration of the region in seconds.
  double durationSeconds(double totalDuration) =>
      (endFraction - startFraction) * totalDuration;

  /// Whether this region contains the given fraction.
  bool contains(double fraction) =>
      fraction >= startFraction && fraction <= endFraction;

  WaveformRegion copyWith({
    double? startFraction,
    double? endFraction,
    Color? color,
    String? label,
  }) {
    return WaveformRegion(
      startFraction: startFraction ?? this.startFraction,
      endFraction: endFraction ?? this.endFraction,
      color: color ?? this.color,
      label: label ?? this.label,
    );
  }
}
