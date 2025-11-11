import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecommerce_admin_app/main.dart';

void main() {
  testWidgets('CheckUser loading indicator shows on startup', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Expect a CircularProgressIndicator on startup (CheckUser screen)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Optionally: wait for frame updates
    await tester.pumpAndSettle();
  });
}
