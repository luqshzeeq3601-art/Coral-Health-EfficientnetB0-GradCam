// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:coral_health_ai/src/app.dart';

void main() {
  testWidgets('renders onboarding startup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CoralHealthApp());
    expect(find.text('Coral'), findsOneWidget);
    expect(find.text('Health AI'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
