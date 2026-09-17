import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: RasaBavarchiApp()));

    await tester.pumpAndSettle();

    expect(find.byType(RasaBavarchiApp), findsOneWidget);
  });
}
