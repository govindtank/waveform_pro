import 'package:flutter/material.dart';

/// A cue marker (bookmark) on the waveform timeline.
class CueMarker {
  /// Position as fraction of total duration (0.0–1.0).
  final double positionFraction;

  /// Label text displayed next to the marker.
  final String label;

  /// Marker color.
  final Color color;

  /// Optional icon displayed on the marker.
  final IconData? icon;

  const CueMarker({
    required this.positionFraction,
    this.label = '',
    this.color = Colors.red,
    this.icon,
  });

  /// Position in seconds given total duration.
  double positionSeconds(double totalDuration) =>
      positionFraction * totalDuration;

  CueMarker copyWith({
    double? positionFraction,
    String? label,
    Color? color,
    IconData? icon,
  }) {
    return CueMarker(
      positionFraction: positionFraction ?? this.positionFraction,
      label: label ?? this.label,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
