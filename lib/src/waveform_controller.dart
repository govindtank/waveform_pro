import 'region.dart';
import 'marker.dart';

/// Controls waveform timeline state: zoom, scroll, regions, and markers.
class WaveformController {
  /// Current zoom level (pixels per sample).
  /// Higher values = more zoomed in.
  double pixelsPerSample;

  /// Maximum allowed pixels per sample (zoom-in limit).
  final double maxPixelsPerSample;

  /// Minimum allowed pixels per sample (zoom-out limit).
  final double minPixelsPerSample;

  /// Current scroll offset in pixels.
  double scrollOffset;

  /// Total width of the waveform in pixels (computed from sample count).
  double _totalWidth = 0;

  /// Width of the visible viewport in pixels.
  double viewportWidth = 0;

  /// Selected regions on the waveform.
  final List<WaveformRegion> regions;

  /// Cue markers on the waveform.
  final List<CueMarker> markers;

  /// Callback when zoom level changes.
  void Function(double pixelsPerSample)? onZoomChanged;

  /// Callback when scroll position changes.
  void Function(double scrollOffset)? onScrollChanged;

  WaveformController({
    double initialPixelsPerSample = 1.0,
    this.maxPixelsPerSample = 100.0,
    this.minPixelsPerSample = 0.1,
    this.scrollOffset = 0.0,
    List<WaveformRegion>? regions,
    List<CueMarker>? markers,
  })  : pixelsPerSample = initialPixelsPerSample,
        regions = regions ?? [],
        markers = markers ?? [];

  /// The visible sample range [start, end] based on scroll and viewport.
  (int, int) get visibleSampleRange {
    final startSample =
        (scrollOffset / pixelsPerSample).floor().clamp(0, _totalSamples);
    final visibleSamples = (viewportWidth / pixelsPerSample).ceil();
    final endSample = (startSample + visibleSamples).clamp(0, _totalSamples);
    return (startSample, endSample);
  }

  /// The visible time range in seconds.
  (double, double) get visibleTimeRange {
    final (start, end) = visibleSampleRange;
    return (start / _samplesPerSecond, end / _samplesPerSecond);
  }

  int _totalSamples = 0;
  double _samplesPerSecond = 1;

  /// Initialize controller with waveform data dimensions.
  void attach(int totalSamples, double samplesPerSecond) {
    _totalSamples = totalSamples;
    _samplesPerSecond = samplesPerSecond;
    _totalWidth = totalSamples * pixelsPerSample;
  }

  /// Zoom in by a factor.
  void zoomIn([double factor = 1.5]) {
    final newPps = (pixelsPerSample * factor)
        .clamp(minPixelsPerSample, maxPixelsPerSample);
    if (newPps != pixelsPerSample) {
      pixelsPerSample = newPps;
      _totalWidth = _totalSamples * pixelsPerSample;
      onZoomChanged?.call(pixelsPerSample);
    }
  }

  /// Zoom out by a factor.
  void zoomOut([double factor = 1.5]) {
    zoomIn(1.0 / factor);
  }

  /// Reset zoom to fit all samples in the viewport.
  void resetZoom() {
    if (viewportWidth > 0 && _totalSamples > 0) {
      pixelsPerSample = (viewportWidth / _totalSamples).clamp(
        minPixelsPerSample,
        maxPixelsPerSample,
      );
      _totalWidth = _totalSamples * pixelsPerSample;
      scrollOffset = 0;
      onZoomChanged?.call(pixelsPerSample);
    }
  }

  /// Add a region selection.
  void addRegion(WaveformRegion region) => regions.add(region);

  /// Remove a region.
  void removeRegion(WaveformRegion region) => regions.remove(region);

  /// Clear all regions.
  void clearRegions() => regions.clear();

  /// Add a cue marker.
  void addMarker(CueMarker marker) => markers.add(marker);

  /// Remove a marker.
  void removeMarker(CueMarker marker) => markers.remove(marker);

  /// Clear all markers.
  void clearMarkers() => markers.clear();

  /// Scroll so that the given time (in seconds) is visible.
  void scrollToTime(double seconds) {
    final sampleIndex = (seconds * _samplesPerSecond).round();
    scrollToSample(sampleIndex);
  }

  /// Scroll so that the given sample index is visible.
  void scrollToSample(int sampleIndex) {
    final targetOffset = sampleIndex * pixelsPerSample - viewportWidth / 2;
    scrollOffset = targetOffset.clamp(
        0.0, (_totalWidth - viewportWidth).clamp(0, double.infinity));
    onScrollChanged?.call(scrollOffset);
  }

  /// Convert a pixel position to a time in seconds.
  double pixelToTime(double pixelX) {
    final sampleIndex = ((scrollOffset + pixelX) / pixelsPerSample).floor();
    return sampleIndex / _samplesPerSecond;
  }

  /// Convert a time in seconds to a pixel X position.
  double timeToPixel(double seconds) {
    final sampleIndex = seconds * _samplesPerSecond;
    return sampleIndex * pixelsPerSample - scrollOffset;
  }
}
