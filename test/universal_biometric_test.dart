//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_biometric/universal_biometric.dart';

void main() {
  testWidgets('Renders main app widget', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    //await tester.pumpWidget(const MyApp());

    // Verify that the splash screen is displayed initially.
    //expect(find.byType(SplashScreen), findsOneWidget);

    // Wait for the splash screen to disappear (assuming it takes 2 seconds).
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify that the home page is displayed after the delay.
    expect(find.byType(HomePage), findsOneWidget);

    // Verify that the USB device information button is present.
    expect(find.text('Get USB Device Information'), findsOneWidget);

    // You can add more tests based on your specific widget hierarchy and behavior.
  });
}
