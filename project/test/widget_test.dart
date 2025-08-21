import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/main.dart';

void main() {
	testWidgets('Counter increments smoke test', (WidgetTester tester) async {
		await tester.pumpWidget(const MyApp());

		// Verify that our counter starts at 0.
		expect(find.byKey(const Key('counter')), findsOneWidget);
		expect(find.text('0'), findsOneWidget);

		// Tap the '+' icon and trigger a frame.
		await tester.tap(find.byType(FloatingActionButton));
		await tester.pump();

		// Verify the counter increments to 1.
		expect(find.text('1'), findsOneWidget);
	});
}
