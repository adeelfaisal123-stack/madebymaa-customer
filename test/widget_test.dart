import 'package:customer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts on provided home', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CustomerApp(
        initialLocale: Locale('en'),
        home: Scaffold(body: Text('home')),
      ),
    );
    expect(find.text('home'), findsOneWidget);
  });
}
