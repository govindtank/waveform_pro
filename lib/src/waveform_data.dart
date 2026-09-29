import 'dart:math' as math;

/// Holds the waveform peak data with multi-resolution pyramid caching.
///
/// Samples are normalized to 0.0–1.0 range and represent the amplitude
/// envelope of an audio signal. The pyramid cache enables efficient
/// rendering at any zoom level without re-decoding the audio.
class WaveformData {
  /// Raw peak samples (normalized 0.0–1.0). Length = number of sample bins.
  final List<double> samples;

  /// Duration of the audio in seconds.
  final double durationSeconds;

  /// Number of pyramid levels for zoom.
  /// Each level halves the resolution.
  final List<List<double>> _pyramid;

  /// Create waveform data from a list of normalized peak samples.
  ///
  /// [samples] should contain amplitude values between 0.0 and 1.0.
  /// [durationSeconds] is the total duration of the audio.
  WaveformData({
    required this.samples,
    required this.durationSeconds,
  }) : _pyramid = _buildPyramid(samples);

  /// Total number of samples.
  int get sampleCount => samples.length;

  /// Duration per sample in seconds.
  double get secondsPerSample =>
      samples.isEmpty ? 0 : durationSeconds / samples.length;

  /// Samples per second.
  double get samplesPerSecond =>
      durationSeconds == 0 ? 0 : samples.length / durationSeconds;

  /// Creates a new [WaveformData] instance with added samples appended,
  /// updating the total duration accordingly.
  WaveformData append(List<double> newSamples, {double? addedDurationSeconds}) {
    final updatedSamples = List<double>.from(samples)..addAll(newSamples);
    final extraDuration = addedDurationSeconds ??
        (samples.isEmpty
            ? 0.0
            : (newSamples.length * (durationSeconds / samples.length)));
    return WaveformData(
      samples: updatedSamples,
      durationSeconds: durationSeconds + extraDuration,
    );
  }

  /// Get the appropriate resolution level for a given viewport width.
  ///
  /// [visibleSamples] is the number of samples that fit in the current viewport.
  /// Returns a reduced-resolution list for efficient rendering.
  List<double> getLevel(int visibleSamples) {
    if (samples.isEmpty) return const [];
    if (visibleSamples >= samples.length) return samples;

    // Find the pyramid level that best matches the target resolution
    int level = 0;
    int levelSize = samples.length ~/ 2;
    while (levelSize > visibleSamples && level < _pyramid.length - 1) {
      level++;
      levelSize ~/= 2;
    }

    return _pyramid[level];
  }

  /// Generate synthetic waveform data for testing/demo.
  ///
  /// Creates realistic-looking audio waveforms with varying amplitudes.
  factory WaveformData.generate({
    int sampleCount = 2000,
    double durationSeconds = 30.0,
    double noiseLevel = 0.1,
  }) {
    final random = _SeededRandom(42);
    final samples = List<double>.generate(sampleCount, (i) {
      final t = i / sampleCount;
      // Create envelope: intro, main, varying sections, outro
      final envelope = _envelope(t);
      // Mix tones + noise
      final tone = 0.3 * _sine(t * 40) + 0.2 * _sine(t * 17 + 0.5);
      final noise = noiseLevel * (random.nextDouble() * 2 - 1);
      final amplitude = (tone + noise).abs().clamp(0.0, 1.0) * envelope;
      return amplitude;
    });
    return WaveformData(samples: samples, durationSeconds: durationSeconds);
  }

  /// Generate a data URL string for debugging/preview purposes.
  String toDataUri() {
    if (samples.isEmpty) return '';
    final buffer = StringBuffer();
    final step = math.max(1, samples.length ~/ 100);
    for (int i = 0; i < samples.length; i += step) {
      buffer.write('${(samples[i] * 100).toStringAsFixed(0)},');
    }
    return buffer.toString();
  }

  // ---- Private helpers ----

  static List<List<double>> _buildPyramid(List<double> samples) {
    if (samples.isEmpty) return [const []];
    final pyramid = <List<double>>[samples];
    var current = samples;
    while (current.length > 64) {
      final reduced = <double>[];
      for (int i = 0; i < current.length - 1; i += 2) {
        reduced.add((current[i] + current[i + 1]) / 2);
      }
      pyramid.add(reduced);
      current = reduced;
    }
    return pyramid;
  }

  static double _envelope(double t) {
    const introEnd = 0.05;
    const outroStart = 0.85;
    if (t < introEnd) return t / introEnd; // fade in
    if (t > outroStart) return (1 - t) / (1 - outroStart); // fade out
    // Varying sections
    final middle = (t - introEnd) / (outroStart - introEnd);
    return 0.6 + 0.4 * _sine(middle * 3 + 1.2).abs();
  }

  static double _sine(double x) => math.sin(x * math.pi * 2);
}

/// Simple seeded random for deterministic waveform generation.
class _SeededRandom {
  int _seed;
  _SeededRandom(this._seed);

  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
}
