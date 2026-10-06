import 'package:bulk_tempo/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MainApp renders Hello World', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MainApp()));

    expect(find.text('Hello World!'), findsOneWidget);
  });
}
