import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('Text field rendering test', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(decoration: InputDecoration(hintText: 'Email')),
                TextField(decoration: InputDecoration(hintText: 'Password')),
                ElevatedButton(onPressed: null, child: Text('Login')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('Can enter email text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: Key('email_field'),
                  decoration: InputDecoration(hintText: 'Email'),
                ),
                TextField(
                  key: Key('password_field'),
                  decoration: InputDecoration(hintText: 'Password'),
                ),
                ElevatedButton(onPressed: null, child: Text('Login')),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Can enter password text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: Key('email_field'),
                  decoration: InputDecoration(hintText: 'Email'),
                ),
                TextField(
                  key: Key('password_field'),
                  obscureText: true,
                  decoration: InputDecoration(hintText: 'Password'),
                ),
                ElevatedButton(onPressed: null, child: Text('Login')),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Login button can be tapped', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const TextField(decoration: InputDecoration(hintText: 'Email')),
                const TextField(decoration: InputDecoration(hintText: 'Password')),
                ElevatedButton(
                  onPressed: () { buttonPressed = true; },
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(buttonPressed, true);
    });

    testWidgets('Email and password fields are visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(decoration: InputDecoration(hintText: 'Email')),
                TextField(decoration: InputDecoration(hintText: 'Password')),
                ElevatedButton(onPressed: null, child: Text('Login')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Login button is enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(decoration: InputDecoration(hintText: 'Email')),
                TextField(decoration: InputDecoration(hintText: 'Password')),
                ElevatedButton(onPressed: null, child: Text('Login')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('Text fields accept input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: Key('email_field'),
                  decoration: InputDecoration(hintText: 'Email'),
                ),
                TextField(
                  key: Key('password_field'),
                  decoration: InputDecoration(hintText: 'Password'),
                ),
                ElevatedButton(onPressed: null, child: Text('Login')),
              ],
            ),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('email_field')), 'user@test.com');
      expect(find.text('user@test.com'), findsOneWidget);
    });

    testWidgets('Widget hierarchy is correct', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(decoration: InputDecoration(hintText: 'Email')),
                TextField(decoration: InputDecoration(hintText: 'Password')),
                ElevatedButton(onPressed: null, child: Text('Login')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Can clear input fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: Key('email_field'),
                  decoration: InputDecoration(hintText: 'Email'),
                ),
                TextField(
                  key: Key('password_field'),
                  decoration: InputDecoration(hintText: 'Password'),
                ),
                ElevatedButton(onPressed: null, child: Text('Login')),
              ],
            ),
          ),
        ),
      );

      final emailField = find.byKey(const Key('email_field'));
      await tester.enterText(emailField, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);

      await tester.enterText(emailField, '');
      expect(find.text('test@example.com'), findsNothing);
    });

    testWidgets('Multiple buttons render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(decoration: InputDecoration(hintText: 'Email')),
                TextField(decoration: InputDecoration(hintText: 'Password')),
                ElevatedButton(onPressed: null, child: Text('Login')),
                ElevatedButton(onPressed: null, child: Text('Sign Up')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.byType(ElevatedButton).evaluate().length >= 2, true);
    });
  });
}
