import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizpilot/app.dart';

void main() {
  testWidgets('BizPilotApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BizPilotApp(),
      ),
    );
    // Settle splash screen transition timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(BizPilotApp), findsOneWidget);
  });
}
