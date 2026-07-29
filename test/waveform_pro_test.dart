import 'package:flutter_test/flutter_test.dart';
import 'package:waveform_pro/waveform_pro.dart';

void main() {
  test('WaveformData generates correct number of samples', () {
    final data = WaveformData.generate(sampleCount: 100, durationSeconds: 10);
    expect(data.sampleCount, 100);
    expect(data.durationSeconds, 10.0);
  });

  test('WaveformData samples are in valid range', () {
    final data = WaveformData.generate(sampleCount: 500, durationSeconds: 30);
    for (final sample in data.samples) {
      expect(sample, greaterThanOrEqualTo(0.0));
      expect(sample, lessThanOrEqualTo(1.0));
    }
  });

  test('WaveformRegion correctly computes duration', () {
    final region = WaveformRegion(startFraction: 0.2, endFraction: 0.8);
    expect(region.durationSeconds(100), closeTo(60.0, 0.001));
  });

  test('WaveformRegion.contains works', () {
    final region = WaveformRegion(startFraction: 0.2, endFraction: 0.8);
    expect(region.contains(0.5), true);
    expect(region.contains(0.1), false);
    expect(region.contains(0.9), false);
  });

  test('WaveformController zoomIn and zoomOut work', () {
    final ctrl = WaveformController(initialPixelsPerSample: 1.0);
    ctrl.zoomIn(2.0);
    expect(ctrl.pixelsPerSample, 2.0);
    ctrl.zoomOut(2.0);
    expect(ctrl.pixelsPerSample, 1.0);
  });

  test('CueMarker positionSeconds works', () {
    const marker = CueMarker(positionFraction: 0.5);
    expect(marker.positionSeconds(100), 50.0);
  });
}
