// This is a basic Flutter widget test for Nota App
//
// Co-authored-by: Ali-0110

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nota/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NotaApp());
    await tester.pumpAndSettle();
    // Verify that the app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
// 
