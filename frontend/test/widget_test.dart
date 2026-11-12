import 'package:flutter_test/flutter_test.dart';
import 'package:appointment_reminder_week13/main.dart';

void main() {
  testWidgets('Appointment Reminder App launches',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AppointmentReminderApp());

    expect(find.byType(AppointmentReminderApp), findsOneWidget);
  });
}
