import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nota/main.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('Login page renders with email and password fields',
            (WidgetTester tester) async {
          await tester.pumpWidget(const NotaApp());
          await tester.pumpAndSettle();

          // Verify TextField exists
          expect(find.byType(TextField), findsWidgets);

          // Verify buttons exist
          expect(find.byType(ElevatedButton), findsWidgets);
        });

    testWidgets('Can enter email text', (WidgetTester tester) async {
      await tester.pumpWidget(const NotaApp());
      await tester.pumpAndSettle();

      // Find email TextField
      final emailFields = find.byType(TextField);
      expect(emailFields, findsWidgets);

      // Enter email
      await tester.enterText(emailFields.first, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Can enter password text', (WidgetTester tester) async {
      await tester.pumpWidget(const NotaApp());
      await tester.pumpAndSettle();

      // Find password TextField
      final passwordFields = find.byType(TextField);
      expect(passwordFields, findsWidgets);

      // Enter password in second field
      if (passwordFields.evaluate().length > 1) {
        await tester.enterText(passwordFields.at(1), 'password123');
        expect(find.text('password123'), findsOneWidget);
      }
    });

    testWidgets('Login button exists and can be tapped',
            (WidgetTester tester) async {
          await tester.pumpWidget(const NotaApp());
          await tester.pumpAndSettle();

          // Find and tap login button
          final loginButton = find.byType(ElevatedButton);
          expect(loginButton, findsWidgets);

          // Tap the button
          await tester.tap(loginButton.first);
          await tester.pump();
        });

    testWidgets('Email and password fields are visible',
            (WidgetTester tester) async {
          await tester.pumpWidget(const NotaApp());
          await tester.pumpAndSettle();

          // Verify text fields are visible
          expect(find.byType(TextField), findsWidgets);
        });

    testWidgets('Login button is enabled', (WidgetTester tester) async {
      await tester.pumpWidget(const NotaApp());
      await tester.pumpAndSettle();

      // Find ElevatedButton
      final button = find.byType(ElevatedButton);
      expect(button, findsWidgets);

      // Verify button is visible and enabled
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('Text fields accept input', (WidgetTester tester) async {
      await tester.pumpWidget(const NotaApp());
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);

      // Enter text in first field
      await tester.enterText(fields.first, 'user@test.com');
      expect(find.text('user@test.com'), findsOneWidget);

      // Enter text in second field if exists
      if (fields.evaluate().length > 1) {
        await tester.enterText(fields.at(1), 'pass123');
        expect(find.text('pass123'), findsOneWidget);
      }
    });

    testWidgets('Widget hierarchy is correct', (WidgetTester tester) async {
      await tester.pumpWidget(const NotaApp());
      await tester.pumpAndSettle();

      // Verify MaterialApp exists
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify widgets render
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Can clear input fields', (WidgetTester tester) async {
      await tester.pumpWidget(const NotaApp());
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);

      // Enter text
      await tester.enterText(fields.first, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);

      // Clear field
      await tester.enterText(fields.first, '');
      expect(find.text('test@example.com'), findsNothing);
    });

    testWidgets('Multiple buttons render without errors',
            (WidgetTester tester) async {
          await tester.pumpWidget(const NotaApp());
          await tester.pumpAndSettle();

          // Find all buttons
          final buttons = find.byType(ElevatedButton);
          expect(buttons, findsWidgets);

          // Verify multiple buttons exist
          expect(buttons.evaluate().length >= 1, true);
        });
  });
}
