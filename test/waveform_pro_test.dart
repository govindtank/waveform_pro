import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waveform_pro/waveform_pro.dart';

void main() {
  test('WaveformData generates correct number of samples', () {
    final data =
        WaveformData.generate(sampleCount: 1000, durationSeconds: 10.0);
    expect(data.sampleCount, 1000);
    expect(data.durationSeconds, 10.0);
    expect(data.samplesPerSecond, 100.0);
    expect(data.secondsPerSample, 0.01);
  });

  test('WaveformData samples are in valid range', () {
    final data = WaveformData.generate(sampleCount: 500);
    for (final sample in data.samples) {
      expect(sample, greaterThanOrEqualTo(0.0));
      expect(sample, lessThanOrEqualTo(1.0));
    }
  });

  test('WaveformData.append works for live recording streams', () {
    final initial =
        WaveformData.generate(sampleCount: 100, durationSeconds: 1.0);
    final appended = initial.append([0.5, 0.8, 0.2]);

    expect(appended.sampleCount, 103);
    expect(appended.durationSeconds, closeTo(1.03, 0.01));
    expect(appended.samples.last, 0.2);
  });

  test('WaveformStyle presets and render modes', () {
    const voiceMemo = WaveformStyle.voiceMemo;
    expect(voiceMemo.renderMode, WaveformRenderMode.bars);
    expect(voiceMemo.barWidth, 3.5);

    const neon = WaveformStyle.neonGlow;
    expect(neon.renderMode, WaveformRenderMode.curvedSpline);

    final modified =
        voiceMemo.copyWith(renderMode: WaveformRenderMode.continuous);
    expect(modified.renderMode, WaveformRenderMode.continuous);
  });

  test('WaveformRegion correctly computes duration', () {
    final region = WaveformRegion(
      startFraction: 0.2,
      endFraction: 0.5,
    );
    expect(region.durationSeconds(10.0), closeTo(3.0, 0.001));
    expect(region.startSeconds(10.0), closeTo(2.0, 0.001));
    expect(region.endSeconds(10.0), closeTo(5.0, 0.001));
  });

  test('WaveformRegion.contains works', () {
    final region = WaveformRegion(
      startFraction: 0.2,
      endFraction: 0.5,
    );
    expect(region.contains(0.3), isTrue);
    expect(region.contains(0.1), isFalse);
    expect(region.contains(0.6), isFalse);
  });

  test('WaveformController zoomIn and zoomOut work', () {
    final controller = WaveformController(initialPixelsPerSample: 1.0);
    controller.attach(1000, 100);

    controller.zoomIn(2.0);
    expect(controller.pixelsPerSample, 2.0);

    controller.zoomOut(2.0);
    expect(controller.pixelsPerSample, 1.0);
  });

  test('CueMarker positionSeconds works', () {
    const marker = CueMarker(positionFraction: 0.5, label: 'Chorus');
    expect(marker.positionSeconds(60.0), 30.0);
    expect(marker.label, 'Chorus');
  });

  testWidgets('WaveformTimeline renders different render modes without error',
      (tester) async {
    final data = WaveformData.generate(sampleCount: 200, durationSeconds: 5.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                WaveformTimeline(
                  data: data,
                  style: WaveformStyle.voiceMemo,
                  playheadPosition: 2.0,
                ),
                WaveformTimeline(
                  data: data,
                  style: WaveformStyle.neonGlow,
                  playheadPosition: 1.5,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(WaveformTimeline), findsNWidgets(2));
    await tester.pumpAndSettle();
  });

  test('WaveformExporter produces valid PNG byte data', () async {
    final data = WaveformData.generate(sampleCount: 100, durationSeconds: 2.0);
    final Uint8List bytes = await WaveformExporter.toPngBytes(
      data: data,
      width: 200,
      height: 80,
      style: WaveformStyle.voiceMemo,
    );

    expect(bytes, isNotEmpty);
    // PNG signature bytes: 137, 80, 78, 71 (0x89, 'P', 'N', 'G')
    expect(bytes[0], 0x89);
    expect(bytes[1], 0x50);
    expect(bytes[2], 0x4E);
    expect(bytes[3], 0x47);
  });
}
