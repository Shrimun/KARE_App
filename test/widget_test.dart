// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:new_kare_1/main.dart';
import 'package:new_kare_1/services/api_service.dart';

void main() {
  testWidgets('App builds and shows MaterialApp', (WidgetTester tester) async {
    final api = ApiService();
    await tester.pumpWidget(MyApp(api: api));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
