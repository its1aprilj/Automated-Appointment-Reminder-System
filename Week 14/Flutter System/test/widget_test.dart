// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appointment_reminder_week13/main.dart';

void main() {
  group('Appointment Reminder System Tests', () {
    test('AppointmentReminderApp can be created', () {
      const app = AppointmentReminderApp();

      expect(app, isA<Widget>());
    });

    testWidgets('Metric card displays its title and value',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: MetricCard(
                  title: 'Total appointments',
                  value: 0,
                  icon: Icons.calendar_month_rounded,
                  accent: Color(0xFF6D28D9),
                ),
              ),
            ),
          );

          expect(find.text('Total appointments'), findsOneWidget);
          expect(find.text('0'), findsOneWidget);
        });

    testWidgets('Metric card displays the correct appointment count',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: MetricCard(
                  title: 'Delivered',
                  value: 5,
                  icon: Icons.mark_email_read_rounded,
                  accent: Color(0xFF16845B),
                ),
              ),
            ),
          );

          expect(find.text('Delivered'), findsOneWidget);
          expect(find.text('5'), findsOneWidget);
        });
  });
}