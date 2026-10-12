import 'package:ecommerce_app_huma_volve/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders splash screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Huma-volve'), findsOneWidget);
    // Advance timer past splash delay
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
