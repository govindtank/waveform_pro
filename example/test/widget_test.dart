import 'package:flutter_test/flutter_test.dart';
import 'package:waveform_pro_example/main.dart';

void main() {
  testWidgets('App loads waveform timeline', (WidgetTester tester) async {
    await tester.pumpWidget(const WaveformProExampleApp());
    expect(find.text('Waveform Pro Demo'), findsOneWidget);
    expect(find.text('Region 10-20s'), findsOneWidget);
    expect(find.text('Marker 50%'), findsOneWidget);
  });
}
