import 'dart:math';
import 'dart:typed_data';
import 'waveform_data.dart';

/// Extracts waveform peak data from audio sources.
///
/// This utility provides methods to generate [WaveformData] from
/// various audio inputs. For production use, pair with `ffmpeg_kit_flutter`
/// or server-side peak extraction.
class PeakExtractor {
  /// Extract peaks from a WAV file bytes.
  ///
  /// Reads 16-bit PCM WAV format and computes peak amplitude envelopes.
  /// [targetSamples] controls the resolution (default: 2000 bins).
  static WaveformData fromWavBytes(
    Uint8List wavBytes, {
    int targetSamples = 2000,
  }) {
    // Parse WAV header
    if (wavBytes.length < 44) {
      throw const FormatException('File too small to be a valid WAV');
    }

    final sampleRate =
        ByteData.sublistView(wavBytes, 24, 28).getUint16(0, Endian.little);
    final bitsPerSample =
        ByteData.sublistView(wavBytes, 34, 36).getUint16(0, Endian.little);
    final dataSize =
        ByteData.sublistView(wavBytes, 40, 44).getUint32(0, Endian.little);

    final totalSamples = dataSize ~/ (bitsPerSample ~/ 8);
    final durationSeconds = totalSamples / sampleRate;

    if (totalSamples == 0) {
      return WaveformData(samples: [0], durationSeconds: 0);
    }

    // Compute peaks
    final peaks = List<double>.filled(targetSamples, 0);
    final samplesPerBin = (totalSamples / targetSamples).ceil();

    int sampleOffset = 44; // Skip WAV header

    for (int bin = 0; bin < targetSamples; bin++) {
      double maxPeak = 0;
      for (int j = 0;
          j < samplesPerBin && sampleOffset + 1 < wavBytes.length;
          j++) {
        if (bitsPerSample == 16) {
          final sample =
              ByteData.sublistView(wavBytes, sampleOffset, sampleOffset + 2)
                  .getInt16(0, Endian.little);
          maxPeak = max(maxPeak, sample.abs() / 32768.0);
          sampleOffset += 2;
        } else if (bitsPerSample == 8) {
          final sample = (wavBytes[sampleOffset] - 128) / 128.0;
          maxPeak = max(maxPeak, sample.abs());
          sampleOffset += 1;
        } else {
          // Skip unsupported bit depths
          sampleOffset += bitsPerSample ~/ 8;
        }
      }
      peaks[bin] = maxPeak.clamp(0.0, 1.0);
    }

    return WaveformData(samples: peaks, durationSeconds: durationSeconds);
  }

  /// Extract peaks from raw PCM float samples.
  ///
  /// [samples] normalized to -1.0..1.0 range.
  /// [sampleRate] in Hz.
  static WaveformData fromPcmFloats(
    List<double> samples, {
    int sampleRate = 44100,
    int targetSamples = 2000,
  }) {
    final durationSeconds = samples.length / sampleRate;
    final peaks = List<double>.filled(targetSamples, 0);
    final samplesPerBin = (samples.length / targetSamples).ceil();

    for (int bin = 0; bin < targetSamples; bin++) {
      double maxPeak = 0;
      final startIdx = bin * samplesPerBin;
      final endIdx = (startIdx + samplesPerBin).clamp(0, samples.length);
      for (int j = startIdx; j < endIdx; j++) {
        maxPeak = max(maxPeak, samples[j].abs());
      }
      peaks[bin] = maxPeak.clamp(0.0, 1.0);
    }

    return WaveformData(samples: peaks, durationSeconds: durationSeconds);
  }

  /// Generate peaks via FFmpeg command.
  ///
  /// [ffmpegPath] path to ffmpeg binary.
  /// [audioPath] path to audio file.
  /// Returns a list of normalized peak values (2000 bins).
  ///
  /// This is a synchronous helper; on mobile use ffmpeg_kit_flutter instead.
  static Future<WaveformData> fromFfmpeg(
    String ffmpegPath,
    String audioPath, {
    int targetSamples = 2000,
  }) async {
    // This method is a stub for server-side or desktop use.
    // On mobile, use ffmpeg_kit_flutter with the `-filter_complex`
    // compand or acompressor to extract peaks.
    throw UnimplementedError(
      'Use fromWavBytes or fromPcmFloats for mobile. '
      'For FFmpeg-based extraction, see package:ffmpeg_kit_flutter',
    );
  }
}
