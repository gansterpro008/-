import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uchettovarov/main.dart';

void main() {
  testWidgets('App loads and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const WarehouseApp(initialTheme: ThemeMode.light));
    expect(find.text('Склад'), findsOneWidget);
  });
}
