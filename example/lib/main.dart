import 'package:flutter/material.dart';
import 'package:waveform_pro/waveform_pro.dart';

void main() => runApp(const WaveformProExampleApp());

class WaveformProExampleApp extends StatelessWidget {
  const WaveformProExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waveform Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WaveformData _data = WaveformData.generate(
    sampleCount: 3000,
    durationSeconds: 30,
  );
  final WaveformController _ctrl = WaveformController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waveform Pro Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            WaveformTimeline(
              data: _data,
              controller: _ctrl,
              height: 140,
              onTap: (t) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${t.toStringAsFixed(1)}s')),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              FilledButton.icon(
                icon: const Icon(Icons.select_all),
                label: const Text('Region 10-20s'),
                onPressed: () {
                  setState(() {
                    _ctrl.clearRegions();
                    _ctrl.addRegion(WaveformRegion(
                      startFraction: 10 / 30,
                      endFraction: 20 / 30,
                    ));
                  });
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => setState(() => _ctrl.clearRegions()),
                child: const Text('Clear'),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.bookmark_add),
                label: const Text('Marker 50%'),
                onPressed: () => setState(() =>
                  _ctrl.addMarker(const CueMarker(
                    positionFraction: 0.5, label: 'Mid',
                  ))),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _ctrl.clearMarkers()),
                child: const Text('Clear markers'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
