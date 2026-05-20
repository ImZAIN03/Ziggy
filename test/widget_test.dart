// Basic smoke test for Ziggy — just verifies the app builds without crashing.
import 'package:flutter_test/flutter_test.dart';
import 'package:ziggy/main.dart';

void main() {
  testWidgets('ZiggyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZiggyApp());
    // The game widget initialises asynchronously; just ensure no immediate crash.
    expect(tester.takeException(), isNull);
  });
}
