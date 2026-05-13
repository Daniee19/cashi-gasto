import 'package:flutter_test/flutter_test.dart';
import 'package:cashi_gasto/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App should build successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CashiGastoApp(),
      ),
    );

    // Verify the app builds without errors
    expect(find.text('Cashi Gasto'), findsAny);
  });
}
