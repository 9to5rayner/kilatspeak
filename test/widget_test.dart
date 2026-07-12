// Basic smoke test for KilatSpeak.
//
// This replaces Flutter's default generated widget_test.dart, which
// referenced a `MyApp` class from the counter-app template — that class
// was removed back in Phase 2 when main.dart was rewritten to use
// KilatSpeakApp, but the stale test was never updated until `flutter
// analyze` caught it in Phase 4.
//
// NOTE: This deliberately does NOT pump the real KilatSpeakApp widget.
// KilatSpeakApp routes to AuthScreen, which calls FirebaseAuth.instance
// in initState() — and Firebase isn't initialized in a plain widget-test
// environment without additional mock setup (firebase_core_platform_
// interface test mocks), which is out of scope for this phase. Testing
// Firebase-dependent screens properly is deferred until we have a real
// testing strategy (likely alongside Phase 5's repository layer, using
// fake/mock repositories rather than hitting real Firebase in tests).
//
// For now this just confirms the test harness itself works, so
// `flutter analyze` and `flutter test` stay green as a baseline.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test: a basic MaterialApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('KilatSpeak test harness OK'),
        ),
      ),
    );

    expect(find.text('KilatSpeak test harness OK'), findsOneWidget);
  });
}
